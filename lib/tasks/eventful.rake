namespace :eventful do
  
  desc "Import eventful categories"
  task :import_categories do
    imported = EventfulFeed::Init.categories
    puts "#{Time.now}: imported #{imported} eventful categories"
  end
  
  desc "Mark cities with events"
  task :mark_cities do
    EventfulFeed::City.all.each do |eventful_city|
      # map to a city object
      city = City.find_by_name(eventful_city.name)
      next if city.blank?
      city.events = 1
      city.save
    end
  end
end