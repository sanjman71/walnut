class EventJob < Struct.new(:params)
  def self.import_priority
    3
  end
  
  def self.remove_prioriy
    3
  end

  def logger
    case RAILS_ENV
    when 'development'
      @logger ||= Logger.new(STDOUT)
    else
      @logger ||= Logger.new("log/events.log")
    end
  end

  def perform
    logger.info "*** #{Time.now}: event job: #{params.inspect}"

    begin
      case params[:method]
      when 'import_all'
        import_all(params)
      when 'import_city'
        import_events(params)
      when 'remove_past'
        remove_past_events
      when 'set_event_counts'
        set_event_counts
      else
        logger.error "#{Time.now}: xxx ignoring method #{params[:method]}"
      end
    rescue Exception => e
      logger.info "xxx #{Time.now}: #{e.message}, #{e.backtrace}"
    end
  end

  def set_event_counts
    [City, Zip, Neighborhood].each do |klass|
      logger.info "*** #{Time.now}: setting #{klass} event counts"
      Locality.set_event_counts(klass)
    end
  end

  def remove_past_events
    # remove all past events
    events = Appointment.public.not_recurring.past
    logger.info "*** #{Time.now}: removing all #{events.size} past non-recurring events"
    events.each { |e| e.destroy }
    logger.info "*** #{Time.now}: completed"
  end

  def import_all(params)
    # find all event cities
    event_cities  = City.min_density(City.popular_density).order_by_density(:include => :state).sort_by { |o| o.name }

    # map certain cities to multiple states
    event_states  = Hash['New York' => [State.find_by_name('New Jersey'), State.find_by_name('New York')]]
    event_limit   = params[:limit] ? params[:limit].to_i : 10

    event_cities.each do |city|
      states = event_states[city.name] || Array(city.state)

      states.each do |state|
        # enqueue job
        logger.info "*** adding event job: #{city.name}:#{state.name}"
        Delayed::Job.enqueue(EventJob.new(:method => 'import_city', :city => city.name, :region => state.name, :limit => event_limit), EventJob.import_priority)
      end
    end
  end

  def import_events(params)
    # build events search conditions
    city      = params[:city] ? City.find_by_name(params[:city].to_s.titleize, :include => :state) : nil
    state     = city.state unless city.blank?
    region    = params[:region] ? params[:region] : ""
    limit     = params[:limit] ? params[:limit].to_i : 1
    max_pages = params[:max_pages] ? params[:max_pages].to_i : 3
    
    if city.blank?
      logger.error "#{Time.now}: xxx missing city"
      return 0
    end

    page        = 1
    per_page    = 50
    imported    = 0
    exists      = 0
    checked     = 0
    missing     = 0
    errors      = 0
    
    start_count = Appointment.public.count

    logger.info "*** #{Time.now}: importing #{city.name} events, limit #{limit}, checking at most #{max_pages * per_page} events"

    while imported < limit and page <= max_pages
      # find future events in the specified city
      conditions = {:location => city.name, :date => 'Future', :page => page, :page_size => per_page, :sort_order => 'popularity'}
      results    = EventStream.search(conditions)
      events     = results['events'] ? results['events']['event'] : []

      logger.info "*** #{Time.now}: processing #{events.size} events"
      
      events.each do |event_hash|
        checked += 1

        if Appointment.public.find_by_source_id(event_hash['id'])
          # event already exists
          exists += 1
          next
        end

        # map eventful event to an event venue
        venue       = EventVenue.find_by_source_id(event_hash['venue_id'])
        city_name   = event_hash['city_name']
        region_name = event_hash['region_name']
        
        if venue.blank? and (city_name == city.name or region == region_name)
          # missing venue in the requested city, add it
          logger.info "*** #{Time.now}: importing venue: #{event_hash['location_name']}:#{event_hash['venue_id']}"
          
          begin
            # get venue info
            venue_hash = EventVenue.get(event_hash['venue_id'])
            # add venue
            venue = EventVenue.import_venue(venue_hash, :log => true)
            # import metadata
            EventVenue.import_metadata(city.name)
            # reload venue
            venue.reload
          rescue Exception => e
            logger.error "xxx #{Time.now}: venue get exception, skipping: #{e.message}"
            errors += 1
            next
          end
        end
        
        if venue.blank?
          # missing venue, but its not in the requested city
          logger.info "xxx #{Time.now}: skipping venue: #{event_hash['location_name']}:#{event_hash['city_name']}:#{event_hash['region_name']}:#{event_hash['address']}:#{event_hash['venue_display']}"
          missing += 1
          next
        end

        if !venue.mapped?
          # map the venue to a location
          begin
            logger.info "*** #{Time.now}: mapping venue - name: #{venue.name}, city: #{venue.city}, address: #{venue.address}"

            venue.map_to_location(:log => true)

            # if its still not mapped, and the confidence value says the location probably doesn't exist, add the venue as a new place
            if !venue.mapped? and venue.confidence == 0
              venue.add_company(:log => true)
            end
          rescue Exception => e
            logger.info "xxx #{Time.now}: mapping exception - #{e.message}"
            next
          end
        end
        
        if !venue.mapped?
          # the venue could not be mapped to a location
          logger.info "xxx #{Time.now}: unmapped venue: #{event_hash['location_name']}:#{event_hash['city_name']}:#{event_hash['region_name']}:#{event_hash['address']}"
          next
        end
      
        # check the location time zone
        if venue.location.timezone.blank?
          logger.info "xxx #{Time.now}: location #{venue.location.id}:#{venue.location.company_name} does not have a timezone"
          next
        end
        
        # import the event
        event = venue.import_event(event_hash, :log => true)

        if event
          # tag the event
          EventVenue.tag_event(event, :log => true)

          # track imported event count
          imported += 1
        end

        break if imported >= limit
      end
      
      page += 1
    end
    
    end_count     = Appointment.public.count
    import_count  = end_count - start_count
    
    logger.info "*** #{Time.now}: completed, checked #{checked} events, imported #{import_count} events, #{exists} already exist, missing #{missing} venues, ended with #{end_count} events"
    
    return import_count
  end

end