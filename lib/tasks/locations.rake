namespace :locations do

  desc "Add location sources"
  task :init_sources do
    puts "#{Time.now}: adding location sources"
    
    added = 0
    
    Location.find_in_batches do |locations|
      locations.each do |location|
        next if location.source_id.blank?
        next if location.location_sources.size > 0
      
        source = LocationSource.new(:location => location, :source_id => location.source_id, :source_type => location.source_type)
        location.location_sources.push(source)
        
        added += 1
      end
    end
    
    puts "#{Time.now}: completed, added #{added} location sources"
  end
  
  desc "Merge locations with same address in the specified CITY"
  task :merge_using_address do
    city = City.find_by_name(ENV["CITY"])
    
    if city.blank?
      puts "missing or invalid city"
      exit
    end
    
    puts "#{Time.now}: merging #{city.name} locations with the same address"
    
    merged  = 0
    groups  = Location.count(:group => :street_address, :conditions => {:city_id => city.id}).delete_if { |name, count| count == 1 or name.blank? }
    
    groups.each do |street_address, count|
      # puts "found #{street_address} #{count} times"
      
      # find all locations with the street address
      locations = Location.find(:all, :conditions => {:city_id => city.id, :street_address => street_address}, :include => :places)
      
      # build hash mapping location names to locations
      names     = locations.inject(Hash.new([])) do |hash, location|
        hash[location.place_name] = hash[location.place_name] + Array(location)
        hash
      end
      
      # merge each name that mapped to more than 1 location at this address
      names.each_pair do |name, collection|
        next if collection.size <= 1
        puts "*** merging #{name}:#{street_address}:#{collection.size}"
        LocationHelper.merge_locations(collection)
        merged += 1
      end
      
      break if merged > 5
    end
    
    puts "#{Time.now}: completed, merged #{merged}"
  end
  
  desc "Initialize location deltas"
  task :init_deltas do 
    s = YAML::load_stream( File.open("data/location_deltas.yml"))
    
    s.documents.each do |object|
      if object["source_id"] and object["source_type"]
        # find location
        location = Location.find_by_source_id_and_source_type(object["source_id"], object["source_type"])

        if location.blank?
          puts "#{Time.now}: xxx could not find location #{object["source_type"]}:#{object["source_id"]}"
          next
        end

        edit_location(location, object)
      else
        # its a new location
        add_location(object)
      end
    end
  end
  
  def edit_location(location, object)
    place = location.place
    
    if object["name"] and place.name != object['name']
      puts "#{Time.now}: *** changing name on location #{location.id} from #{place.name} to #{object["name"]}"
      place.name = object["name"]
      place.save
    end
    
    if object["street_address"] and location.street_address != object["street_address"]
      puts "#{Time.now}: *** changing address on location #{location.id} from #{location.street_address} to #{object["street_address"]}"
      location.street_address = object["street_address"]
      location.save
    end
  end
  
  def add_location(object)
    # check if location/place exists before adding
    places    = Place.find(:all, :conditions => {:name => object['name']})
    
    if places.size > 0
      puts "#{Time.now}: xxx place #{object['name']} already exists"
      return
    end
    
    # check that the city exists
    city = City.find_by_name(object["city"])
    
    if city.blank?
      puts "#{Time.now}: xxx city #{object["city"]} is invalid"
      return
    end
    
    puts "#{Time.now}: *** adding location #{object["name"]}:#{object["city"]}"
    
    location = PlaceHelper.add_place(object)
  end
end