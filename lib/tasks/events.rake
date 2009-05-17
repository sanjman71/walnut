namespace :events do
  
  @@max_per_page  = 100
  
  desc "Initialize event categories and category tags."
  task :init => ["import_categories", "import_category_tags"]
  
  desc "Import event categories from eventful"
  task :import_categories do
    puts "#{Time.now}: importing eventful categories"
    imported = EventCategory.import
    puts "#{Time.now}: imported #{imported} eventful categories"
  end

  desc "Initialize tags for each category"
  task :import_category_tags do
    klass     = EventCategory
    columns   = [:name, :tags]
    file      = "#{RAILS_ROOT}/data/event_categories.txt"
    values    = []
    options   = { :validate => false }
    imported  = 0
    
    puts "#{Time.now}: adding category tags, parsing file #{file}" 
    FasterCSV.foreach(file, :row_sep => "\n", :col_sep => '|') do |row|
      name, tags = row
      
      # find event category by name
      next unless event_category = EventCategory.find_by_name(name)
      
      event_category.tags = tags.strip
      event_category.save
      imported += 1
    end

    puts "#{Time.now}: completed, added tags to #{imported} categories" 
  end

  desc "Apply category tags to events"
  task :apply_category_tags do
    puts "#{Time.now}: applying category tags to all events in each category"
    EventCategory.all.each do |event_category|
      event_category.events.each do |event|
        event.apply_category_tags!(event_category)
      end
    end
    puts "#{Time.now}: completed"
  end

  # desc "Import CITY event venues from eventful"
  # task :import_venues do
  #   limit = ENV["LIMIT"] ? ENV["LIMIT"].to_i : 10
  #   city  = ENV["CITY"] ? City.find_by_name(ENV["CITY"].to_s) : nil
  #   
  #   if city.blank?
  #     puts "usage: missing or invalid CITY"
  #     exit
  #   end
  #   
  #   page      = 1
  #   per_page  = 10
  #   imported  = 0
  #   
  #   puts "#{Time.now}: importing #{limit} #{city.name} eventful venues"
  # 
  #   while imported < limit
  #     imported += EventVenue.import(city, :page => page, :per_page => per_page, :log => true)
  #     page     += 1
  #   end
  #   
  #   puts "#{Time.now}: imported #{imported} #{city.name} eventful venues"
  # end
  
  # desc "Import event venue metadata, e.g. search name, address name ..."
  # task :import_venue_metadata do
  #   count = EventVenue.import_metadata
  #   puts "#{Time.now}: completed, updated #{count} venues"
  # end
  
  desc "Import popular CITY events from eventful"
  task :import_popular_events do
    # build events search conditions
    city  = ENV["CITY"] ? City.find_by_name(ENV["CITY"].to_s.titleize) : nil
    limit = ENV["LIMIT"] ? ENV["LIMIT"].to_i : 1

    if city.blank?
      puts "usage: missing CITY"
      exit
    end

    puts "#{Time.now}: importing #{city.name} events, limit #{limit}"

    page        = 1
    per_page    = 50
    imported    = 0
    checked     = 0
    missing     = 0
    errors      = 0
    istart      = Event.count
    
    while imported < limit
      # find future events in the specified city
      conditions = {:location => city.name, :date => 'Future', :page => page, :page_size => per_page, :sort_order => 'popularity'}
      results    = EventStream::Search.call(conditions)
      events     = results['events'] ? results['events']['event'] : []

      events.each do |event_hash|
        checked += 1
        
        # map eventful event to an event venue
        venue       = EventVenue.find_by_source_id(event_hash['venue_id'])
        city_name   = event_hash['city_name']
        
        if venue.blank? and city_name == city.name
          # missing venue in the requested city, add it
          puts "#{Time.now}: adding venue: #{event_hash['venue_name']}:#{event_hash['venue_id']}"
          
          begin
            # get venue info
            venue_hash = EventVenue.get(event_hash['venue_id'])
            # add venue
            venue = EventVenue.import_venue(venue_hash, :log => true)
            # apply metadata
            EventVenue.import_metadata(city.name)
          rescue Exception => e
            puts "#{Time.now}: xxx venue get exception, skipping: #{e.message}"
            errors += 1
            next
          end
        end
        
        if venue.blank?
          # missing venue, but its not in th requested city
          puts "#{Time.now}: xxx missing venue: #{event_hash['venue_name']}:#{event_hash['city_name']}:#{event_hash['region_name']}"
          missing += 1
          next
        end

        if !venue.mapped?
          # map the venue to a location if we need to
          venue.map_to_location(:log => true)

          # skip adding venues as locations for now
          # if !venue.mapped?
          #   # if its still not mapped, add the venue as a new place and location
          #   venue.add_place(:log => true)
          # end
        end
        
        if !venue.mapped?
          # the venue could not be mapped to location
          puts "#{Time.now}: xxx unmapped venue: #{event_hash['venue_name']}:#{event_hash['city_name']}:#{event_hash['region_name']}"
          next
        end
      
        if Event.find_by_source_id(event_hash['id'])
          # event already exists
          next
        end
        
        # import the event
        event = venue.import_event(event_hash, :log => true)
      
        if event
          # tag the event
          EventVenue.tag_event(event, :log => true)
        
          # mark as popular
          event.popular!

          # track imported event count
          imported += 1
        end

        break if imported >= limit
      end
      
      page += 1
    end
    
    iend = Event.count

    puts "#{Time.now}: completed, checked #{checked} events, imported #{iend - istart} events, ended with #{iend} events"
  end
  
  desc "Tag all events in a city"
  task :tag_events do
    city  = ENV["CITY"] ? City.find_by_name(ENV["CITY"].to_s.titleize) : nil

    if city.blank?
      puts "usage: missing CITY"
      exit
    end

    puts "#{Time.now}: tagging #{city.name} events"
    
    EventVenue.city(city.name).mapped.each do |venue|
      puts "#{Time.now}: tagging venue #{venue.name}:#{venue.city}:#{venue.state} events"
      
      venue.events.each do |event|
        EventVenue.tag_event(event, :log => true)
      end
    end
    
    puts "#{Time.now}: completed"
  end
  
  desc "Remove all events"
  task :remove_all do
    puts "#{Time.now}: removing all #{Event.count} events"
    
    Event.all.each do |event|
      event.event_venue.events.delete(event) unless event.event_venue.blank?
      event.location.events.delete(event) unless event.location.blank?
      event.destroy
    end
    
    puts "#{Time.now}: completed"
  end
end