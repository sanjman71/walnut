namespace :localities do
  namespace :city do
    
    desc "Rename city FROM to city TO, moving all associated locations"
    task :rename do
      city_from_name = ENV["FROM"]
      city_to_name   = ENV["TO"]
      
      if city_from_name.blank? or city_to_name.blank?
        puts "usage: missing FROM or TO"
        exit
      end
      
      city_from = City.find_by_name(city_from_name)
      city_to   = City.find_by_name(city_to_name)
      
      if city_from.blank?
        puts "usage: could not find city #{city_from_name}"
        exit
      end

      if city_to.blank?
        puts "usage: could not find city #{city_to_name}"
        exit
      end
      
      puts "#{Time.now}: renaming city #{city_from.name} to #{city_to.name}: moving #{city_from.locations_count} locations and #{city_from.neighborhoods_count} neighborhoods"
      
      city_from.locations.each do |location|
        location.city = city_to
        location.save
      end

      city_from.neighborhoods.each do |neighborhood|
        neighborhood.city = city_co
        neighborhood.save
      end
      
      # reload city, check counter cache values
      city_from.reload
      
      if city_from.locations_count != 0 or city_from.neighborhoods_count != 0
        puts "#{Time.now}: xxx error, city #{city_from.name} locations or neighborhoods count not 0"
        exit
      end
      
      # remove city
      city_from.destroy
      
      puts "#{Time.now}: completed"
    end
    
  end # city namespace
end