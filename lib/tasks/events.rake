namespace :events do
  
  desc "Initialize event categories, event venues."
  task :init => ["import_categories", "import_venues"]
  
  desc "Import event categories from eventful"
  task :import_categories do
    puts "#{Time.now}: importing eventful categories"
    imported = EventStream::Init.categories
    puts "#{Time.now}: imported #{imported} eventful categories"
  end

  # desc "Create cities with events"
  # task :create_cities do
  #   # initialize cities
  #   ["Chicago", "Charlotte", "New York", "Philadelphia"].sort.each do |s|
  #     EventCity.create(:name => s)
  #   end
  #   
  #   puts "#{Time.now}: #{EventCity.count} cities are considered event cities"
  # end
  # 
  # desc "Mark cities with events"
  # task :mark_cities do
  #   marked = 0
  #   
  #   EventCity.all.each do |event_city|
  #     # map to a city object
  #     city = City.find_by_name(event_city.name)
  #     next if city.blank?
  #     city.events = 1
  #     city.save
  #     marked += 1
  #   end
  #   
  #   puts "#{Time.now}: marked #{marked} cities as having events"
  # end

  desc "Import event venues from eventful"
  task :import_venues do
    puts "#{Time.now}: importing eventful venues"
    limit = ENV["LIMIT"] ? ENV["LIMIT"].to_i : 100
    imported = EventStream::Init.venues(:limit => limit)
    puts "#{Time.now}: imported #{imported} eventful venues"
  end
  
  desc "Map event venues to locations, using sphinx to match locations"
  task :map_venues do
    marked = 0
    
    EventVenue.unmapped.each do |venue|
      city = City.find_by_name(venue.city)
      if city.blank?
        puts "#{Time.now}: xxx could not find venue city #{venue.city}"
        next
      end
      
      # search for venue by city and street address
      components = StreetAddress.components(venue.address)
      address    = "#{components[:housenumber]} #{components[:streetname]}"
      matches    = Location.search(venue.name, :conditions => {:city_id => city.id, :street_address => address})
      if matches.blank?
        puts "#{Time.now}: xxx no search matches for venue #{venue.name}, address #{address}"
        next
      elsif matches.size > 1
        # too many matches
        puts "#{Time.now}: xxx found #{matches.size} matches for venue #{venue.name}, address #{address}"
        next
      end
      
      # mark location as an event venue
      location = matches.first
      venue.location = location
      venue.save
      marked += 1
      
      puts "#{Time.now}: *** marked location #{location.place.name}:#{location.street_address} as an event venue for #{venue.name}"
    end
    
    puts "#{Time.now}: completed, marked #{marked} locations as event venues"
  end
  
  desc "Import events"
  task :import_events do
    # build events search conditions
    @city = ENV["CITY"] ? ENV["CITY"] : City.first

    puts "#{Time.now}: importing #{@city.name} events"

    @conditions = {:location => @city.name, :date => 'Future', :page_size => 50, :sort_order => 'popularity'}
    @results    = EventStream::Search.call(@conditions)
    @events     = @results['events'] ? @results['events']['event'] : []
    @istart     = Event.count

    # import events for all mapped venues
    EventVenue.mapped.each do |venue|
      begin
        @results  = venue.get
        @events   = @results['events']['event']
      rescue Exception => e
        puts "xxx exception: #{e.message}"
        next
      end
      
      next if @events.blank?
      
      @events.each do |event|
        puts "*** #{event['title']}, url: #{event['url']}"

        options = {:name => event['title'], :url => event['url'], :source_type => venue.source_type, :source_id => event['id']}
        options[:start_at]  = event['start_time'] if event['start_time']
        options[:end_at]    = event['stop_time'] if event['stop_time']
        # create event with associated venue
        venue.events.push(Event.create(options))
      end
      
      venue.events.each do |event|
        begin
          @results    = event.get
          @categories = @results['categories']['category']
        rescue Exception => e
          puts "xxx exception: #{e.message}"
          next
        end

        # map to an event category object
        @categories = @categories.map do |category|
          puts "*** category: #{category}"
          EventCategory.find_by_source_id(category['id'])
        end
        
        # associate event categories with events
        @categories.compact.each do |category|
          puts "*** category: #{category}, event: #{event}"
          event.event_categories.push(category)
        end
      end
    end
    
    # @events.each do |event|
    #   # lookup the event venue
    #   next if (venue = EventVenue.find_by_source_id_and_source_type(event['venue_id'], 'eventful')).blank?
    # 
    #   puts "*** creating event #{event['title']} @ #{venue.name}"
    #   
    #   options = {:name => event['title'], :url => event['url'], :source_type => venue.source_type, :source_id => event['id']}
    #   options[:start_at]  = event['start_time'] if event['start_time']
    #   options[:end_at]    = event['stop_time'] if event['stop_time']
    #   venue.events.push(Event.create(options))
    # end

    @iend = Event.count

    puts "#{Time.now}: completed, #{@iend} total events, imported #{@iend - @istart} events"
  end
end