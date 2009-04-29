namespace :events do
  
  @@max_per_page  = 100
  
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

  desc "Mark popular events"
  task :mark_popular_events do
    # build events search conditions
    @city = ENV["CITY"] ? ENV["CITY"] : City.first

    puts "#{Time.now}: marking popular #{@city.name} events"
    
    @conditions = {:location => @city.name, :date => 'Future', :page_size => @@max_per_page, :sort_order => 'popularity'}
    @results    = EventStream::Search.call(@conditions)
    @events     = @results['events'] ? @results['events']['event'] : []
    @popular    = 0
    
    puts "#{Time.now}: *** found #{@events.size} popular events"
    
    @events.each do |eventful|
      next if (event = Event.find_by_source_id(eventful['id'])).blank?
      event.popular!(true)
      @popular += 1
    end
    
    puts "#{Time.now}: completed, marked #{@popular} events as popular"
  end
  
  desc "Import venue events"
  task :import_venue_events do
    # build events search conditions
    @city = ENV["CITY"] ? ENV["CITY"] : City.first

    puts "#{Time.now}: importing #{@city.name} venue events"

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
      
      @events.each do |eventful|
        options = {:name => eventful['title'], :url => eventful['url'], :source_type => venue.source_type, :source_id => eventful['id']}
        options[:start_at]  = eventful['start_time'] if eventful['start_time']
        options[:end_at]    = eventful['stop_time'] if eventful['stop_time']

        next if event = Event.find_by_source_id(eventful['id'])

        puts "*** #{eventful['title']}, url: #{eventful['url']}"

        # create event with associated venue
        venue.events.push(Event.create(options))
      end
      
      venue.events.each do |event|
        # skip if event already has categories
        next if !event.event_categories.blank?
        
        begin
          @results    = event.get
          @categories = @results['categories']['category']
        rescue Exception => e
          puts "xxx exception: #{e.message}"
          next
        end

        # map eventful category id to an event category object
        @categories = @categories.map do |category|
          puts "*** category: #{category}"
          EventCategory.find_by_source_id(category['id'])
        end
        
        # associate event categories with events
        @categories.compact.each do |category|
          puts "*** category: #{category.name}, event: #{event.name}"
          event.event_categories.push(category)
        end
      end
    end

    @iend = Event.count

    puts "#{Time.now}: completed, #{@iend} total events, imported #{@iend - @istart} events"
  end
end