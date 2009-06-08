namespace :locations do

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