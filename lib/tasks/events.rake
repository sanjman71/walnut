namespace :events do
  
  desc "Import event categories from eventful"
  task :import_categories do
    imported = EventStream::Init.categories
    puts "#{Time.now}: imported #{imported} eventful categories"
  end

  desc "Create cities with events"
  task :create_cities do
    # initialize cities
    ["Chicago", "Charlotte", "New York", "Philadelphia"].sort.each do |s|
      EventCity.create(:name => s)
    end
    
    puts "#{Time.now}: #{EventCity.count} cities are considered event cities"
  end
  
  desc "Mark cities with events"
  task :mark_cities do
    marked = 0
    
    EventCity.all.each do |event_city|
      # map to a city object
      city = City.find_by_name(event_city.name)
      next if city.blank?
      city.events = 1
      city.save
      marked += 1
    end
    
    puts "#{Time.now}: marked #{marked} cities as having events"
  end

  desc "Import event venues from eventful"
  task :import_venues do
    imported = EventStream::Init.venues(:limit => 100)
    puts "#{Time.now}: imported #{imported} eventful venues"
  end
  
  desc "Mark locations that are event venues"
  task :mark_venues do
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
      
      puts "#{Time.now}: *** marked location #{location.locatable.name}:#{location.street_address} as an event venue for #{venue.name}"
    end
    
    puts "#{Time.now}: completed, marked #{marked} locations as event venues"
  end
  
end