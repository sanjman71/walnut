namespace :events do
  
  desc "Import event categories from eventful"
  task :import_categories do
    imported = EventStream::Init.categories
    puts "#{Time.now}: imported #{imported} eventful categories"
  end

  desc "Import event venues from eventful"
  task :import_venues do
    imported = EventStream::Init.venues(:limit => 100)
    puts "#{Time.now}: imported #{imported} eventful venues"
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
end