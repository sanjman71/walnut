namespace :neighbors do
  
  desc "Initialize neighbors for all locations"
  task :init_all do
    puts "#{Time.now}: initializing neighbors for all locations"
    
    page        = 1
    page_size   = 1000
    
    # Note: the 'find_in_batches' method messes up the sql conditions for all nested sql calls
    while (locations = Location.find(:all, :offset => (page-1) * page_size, :limit => page_size)).size > 0
      locations.each do |location|
        set_location_neighbors(location)
      end
      puts "#{Time.now}: #{page * page_size} locations processed"
      page += 1
    end
    
    puts "#{Time.now}: completed" 
  end

  desc "Initialize neighbors for all city locations"
  task :init_by_city do
    city    = City.find_by_name(ENV["CITY"].titleize) if ENV["CITY"]
    limit   = ENV["LIMIT"] ? ENV["LIMIT"].to_i : 2**30
    filter  = ENV["FILTER"] if ENV["FILTER"]
    
    if city.blank?
      puts "*** invalid city"
      exit
    end

    puts "#{Time.now}: initializing neighbors for all #{city.name} locations"

    page        = 1
    page_size   = 1000

    # Note: the 'find_in_batches' method messes up the sql conditions for all nested sql calls
    while (locations = Location.find(:all, :conditions => {:city_id => city.id}, :offset => (page-1) * page_size, :limit => page_size)).size > 0
      locations.each do |location|
        if filter
          # apply filter
          next unless "#{location.id}:#{location.name}".match(/#{filter}/)
        end
        set_location_neighbors(location)
      end
      puts "#{Time.now}: #{page * page_size} locations processed"
      page += 1
    end
    
    puts "#{Time.now}: completed" 
  end
  
  desc "Initialize neighbors based on city popular tags"
  task :init_by_city_popular_tags do
    city        = City.find_by_name(ENV["CITY"].titleize) if ENV["CITY"]
    limit       = ENV["LIMIT"] ? ENV["LIMIT"].to_i : 2**30
    
    if city.blank?
      puts "*** invalid city"
      exit
    end

    puts "#{Time.now}: importing #{city.name} neighbors, limit #{limit}"
    
    per_page    = 10
    page        = 1
    added       = 0

    # find popular tags
    tags        = popular_tags(city, :limit => 100)

    tags.each do |tag|
      # find locations tagged with 'tag'

      puts "#{Time.now}: *** tag: #{tag.name}"
      
      hash        = Search.query(tag.name)
      query       = hash[:query_or]
      attributes  = Search.attributes(city)
      klasses     = [Location]
      locations   = ThinkingSphinx::Search.search(query, :classes => klasses, :with => attributes,
                                                  :match_mode => :extended, :page => page, :per_page => per_page,
                                                  :order => :popularity, :sort_mode => :desc)


      locations.each do |location|
        added += set_location_neighbors(location)
      end
    end
    
    puts "#{Time.now}: completed, added neighbors to #{added} locations"
  end
  
  # desc "Initialize neighbors for locations with neighborhoods"
  # task :init_by_neighborhoods do
  #   city        = City.find_by_name(ENV["CITY"].titleize) if ENV["CITY"]
  #   limit       = ENV["LIMIT"] ? ENV["LIMIT"].to_i : 2**30
  #   per_page    = 10
  #   page        = 1
  #   added       = 0
  # 
  #   if city.blank?
  #     puts "*** invalid city"
  #     exit
  #   end
  # 
  #   puts "#{Time.now}: initializing neighbors for #{city.name} locations with neighborhoods"
  # 
  #   # find locations by city, with neighborhoods mapped by urban mapping
  #   while !(locations = Location.for_city(city).urban_mapped.with_neighborhoods.all(:offset => (page - 1) * per_page, :limit => per_page)).blank?
  #     locations.each do |location|
  #       added += set_location_neighbors(location)
  #     end
  #     page += 1
  #   end
  #   
  #   puts "#{Time.now}: completed, added neighbors to #{added} locations"
  # end
  
  def set_location_neighbors(location)
    # check city and lat/lng coordinates
    return 0 if location.blank? or location.city.blank? or !location.mappable?
    # check if location has neighbors
    return 0 if location.location_neighbors.size > 0

    LocationNeighbor.set_neighbors(location, :limit => LocationNeighbor.default_limit, :geodist => 0.0..LocationNeighbor.default_radius_meters)
    
    return 1
  end
end