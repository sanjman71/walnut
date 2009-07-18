namespace :timezones do
  
  desc "Add timezones to cities"
  task :add_to_cities do
    # find all cities without timezones
    cities = City.no_timezones.with_latlng
    added  = 0
    
    puts "#{Time.now}: found #{cities.size} cities with coordinates and no timezones"
    
    cities.each do |city|
      timezone = Geonames::Timezone.get(city.lat, city.lng)
      
      if timezone
        city.timezone = timezone
        city.save
        added += 1
      end
      
      puts "*** mapped #{city.name} to #{timezone.name}"
      break
    end
    
    puts "#{Time.now}: added timezones to #{added} cities"
  end
end

