namespace :timezones do
  
  desc "Add timezones to cities"
  task :add_to_cities do
    # find all cities without timezones
    limit  = ENV["LIMIT"] ? ENV["LIMIT"].to_i : 2**30
    cities = City.no_timezones.with_latlng.all(:order => 'locations_count DESC')
    added  = 0
    
    puts "#{Time.now}: found #{cities.size} cities with coordinates and no timezones"
    
    cities.each do |city|
      timezone = Geonames::Timezone.get(city.lat, city.lng)

      if timezone.blank?
        puts "#{Time.now}: xxx could not map #{city.name} to a timezone"
        next
      end

      puts "#{Time.now}: *** mapped #{city.name} to #{timezone.name}"
      
      if timezone
        city.timezone = timezone
        city.save
        added += 1
      end
      
      break if added >= limit
    end
    
    puts "#{Time.now}: added timezones to #{added} cities"
  end
end

