namespace :events do
  
  @@max_per_page  = 100
  
  desc "Initialize event categories, event venues."
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

  desc "Import CITY event venues from eventful"
  task :import_venues do
    limit = ENV["LIMIT"] ? ENV["LIMIT"].to_i : 100
    city  = ENV["CITY"] ? City.find_by_name(ENV["CITY"].to_s) : nil
    
    if city.blank?
      puts "usage: missing or invalid CITY"
      exit
    end
    
    page      = 1
    per_page  = 10
    imported  = 0
    
    puts "#{Time.now}: importing #{limit} #{city.name} eventful venues"

    while imported < limit
      imported += EventVenue.import(city, :page => page, :per_page => per_page, :log => true)
      page     += 1
    end
    
    puts "#{Time.now}: imported #{imported} #{city.name} eventful venues"
  end
  
  desc "Import event venue metadata, e.g. search name, address name ..."
  task :import_venue_metadata do
    
    file = "#{RAILS_ROOT}/data/event_venues.txt"
    puts "#{Time.now}: parsing file #{file}" 
    FasterCSV.foreach(file, :row_sep => "\n", :col_sep => '|') do |row|
      name, search_name, search_address = row
    
      # find event venue
      event_venue = EventVenue.find_by_name(name)
      next if event_venue.blank?
      
      # apply metadata
      options = {}
      options[:search_name]     = search_name unless search_name.blank?
      options[:search_address]  = search_address unless search_address.blank?
      
      next if options.blank?
      
      event_venue.update_attributes(options)
    end
  end
  
  desc "Map CITY event venues to locations, using sphinx to match locations"
  task :map_venues do
    filter      = ENV["FILTER"].to_s
    city_name   = ENV["CITY"].to_s
    checked     = 0
    marked      = 0
    skipped     = 0

    # find count of already mapped venues
    mapped      = EventVenue.city(city_name).mapped.size
    
    if city_name.blank?
      puts "usage: missing CITY"
      exit
    end
    
    EventVenue.city(city_name).unmapped.each do |venue|
      city = City.find_by_name(venue.city)
      
      if city.blank?
        puts "#{Time.now}: xxx could not find venue city #{venue.city}"
        next
      end
      
      checked += 1
      
      # search for venue by name (try search name first), and by city and street address (try address name first)
      if !venue.search_name.blank?
        # use exact search name
        name    = venue.search_name
      else
        # create search object to build query
        search  = Search.parse([], venue.name)
        name    = search.query
      end 
      
      # break street address into components and normalize
      components  = StreetAddress.components(venue.address)
      address     = venue.search_address.blank? ? StreetAddress.normalize("#{components[:housenumber]} #{components[:streetname]}") : venue.search_address
      
      if filter
        # apply filter
        next unless name.match(/#{filter}/i)
      end
      
      # check if there a source id and type
      if venue.location_source_id and venue.location_source_type
        # find the location
        matches = Location.find(:all, :conditions => {:source_id => venue.location_source_id, :source_type => venue.location_source_type})
      else
        # search with constraints
        matches = Location.search(name, :conditions => {:city_id => city.id, :street_address => address})
      end
      
      if matches.blank?
        puts "#{Time.now}: xxx no search matches for venue '#{name}', address #{address}"
        skipped += 1
        next
      elsif matches.size > 1

        if search.blank?
          # too many matches
          puts "#{Time.now}: xxx found #{matches.size} matches for venue '#{name}', address #{address}"
          skipped += 1
          next
        end

        # try again with a more restrictive search
        puts "#{Time.now}: found #{matches.size} matches for venue #{name}, address #{address} ... trying again"

        name    = search.query(:operator => :and)
        matches = Location.search(name, :conditions => {:city_id => city.id, :street_address => address})
        
        if matches.size != 1
          puts "#{Time.now}: xxx retry, found #{matches.size} matches for venue #{name}, address #{address}"
          skipped += 1
          next
        end
      end
      
      # mark location as an event venue
      location = matches.first
      venue.location = location
      venue.save
      marked += 1
      
      puts "#{Time.now}: *** marked location #{location.place.name}:#{location.street_address} as event venue:#{venue.name}"
    end
    
    puts "#{Time.now}: completed, #{mapped} already mapped event venues, checked #{checked}, marked #{marked}, skipped #{skipped}"
  end

  desc "Import popular CITY events from eventful"
  task :import_popular_events do
    # build events search conditions
    city  = ENV["CITY"] ? City.find_by_name(ENV["CITY"].to_s.titleize) : nil
    limit = ENV["LIMIT"] ? ENV["LIMIT"].to_i : 100

    if city.blank?
      puts "usage: missing CITY"
      exit
    end

    puts "#{Time.now}: importing #{city.name} events for mapped venues, limit #{limit}"

    per_page    = 50
    imported    = 0
    @conditions = {:location => city.name, :date => 'Future', :page_size => per_page, :sort_order => 'popularity'}
    @results    = EventStream::Search.call(@conditions)
    @events     = @results['events'] ? @results['events']['event'] : []
    @istart     = Event.count

    @events.each do |eventful_event|
      # map eventful event to an event venue
      venue = EventVenue.find_by_source_id(eventful_event['venue_id'])
      
      if venue.blank?
        puts "xxx missing venue: #{eventful_event['venue_name']}"
        next
      end
      
      if !venue.mapped?
        puts "xxx unmapped venue: #{eventful_event['venue_name']}"
        next
      end
      
      # import the event
      event = venue.import_event(eventful_event, :log => true)
      
      # mark the event as popular
      event.popular! unless event.blank?
    end
    
    @iend = Event.count

    puts "#{Time.now}: completed, #{@iend} total events, imported #{@iend - @istart} events"
  end
  
  desc "Remove events"
  task :remove_events do
    puts "#{Time.now}: removing all events"
    
    Event.all.each do |event|
      event.event_venue.events.delete(event)
      event.location.events.delete(event)
      event.destroy
    end
    
    puts "#{Time.now}: completed"
  end
end