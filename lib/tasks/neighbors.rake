namespace :neighbors do

  desc "Print neighbor stats"
  task :stats do
    # find cities by density
    density = 25000
    cities  = City.min_density(density).order_by_density
    
    puts "#{Time.now}: found #{cities.size} cities with more than #{density} locations"
    
    cities.each do |city|
      # use the :group option to get around a rails activerecord bug where the group-by clause is lost when using count
      city_locations_with_neighbors   = LocationNeighbor.with_city(city).count(:group => "location_id").length
      city_locations_neighbors_ratio  = city_locations_with_neighbors.to_f / city.locations_count.to_f
      puts "#{Time.now}: city: #{city.name}, neighbors/locations: #{city_locations_with_neighbors}/#{city.locations_count}, ratio: #{city_locations_neighbors_ratio}"
    end

    locations_with_no_neighbors = Location.no_neighbors.with_latlng.count
    puts "#{Time.now}: all: no neighbors/locations: #{locations_with_no_neighbors}/#{Location.count}"

    puts "#{Time.now}: completed"
  end
  
  desc "Initialize neighbors for all locations"
  task :init_all do
    limit   = ENV["LIMIT"] ? ENV["LIMIT"].to_i : 2**30
    filter  = ENV["FILTER"] if ENV["FILTER"]
    sleep   = ENV["SLEEP"] ? ENV["SLEEP"].to_i : 0

    puts "#{Time.now}: initializing neighbors for all locations with no existing neighbors, limit: #{limit}"

    page        = 1
    page_size   = 1000
    ids         = Location.no_neighbors.with_latlng.all(:select => 'id', :limit => limit).collect(&:id)

    puts "#{Time.now}: found #{ids.size} matching location ids"

    exit

    neighbors   = init_neighbors(ids, page, page_size, :filter => filter, :limit => limit, :sleep => sleep)

    puts "#{Time.now}: completed, added neighbors to #{neighbors} locations" 
  end

  desc "Initialize neighbors for all city locations"
  task :init_by_city do
    city    = City.find_by_name(ENV["CITY"].titleize) if ENV["CITY"]
    limit   = ENV["LIMIT"] ? ENV["LIMIT"].to_i : 2**30
    filter  = ENV["FILTER"] if ENV["FILTER"]
    offset  = ENV["OFFSET"] ? ENV["OFFSET"].to_i : 0
    sleep   = ENV["SLEEP"] ? ENV["SLEEP"].to_i : 0

    if city.blank?
      puts "*** invalid city"
      exit
    end

    puts "#{Time.now}: initializing neighbors for #{city.name} locations with no existing neighbors, offset: #{offset} limit #{limit}"

    page        = 1
    page_size   = 1000
    ids         = Location.no_neighbors.with_latlng.all(:all, :offset => offset, :limit => limit, :conditions => {:city_id => city.id}, :select => 'id').collect(&:id)

    puts "#{Time.now}: found #{ids.size} matching location ids"

    neighbors   = init_neighbors(ids, page, page_size, :filter => filter, :limit => limit, :sleep => sleep)

    puts "#{Time.now}: completed, added neighbors to #{neighbors} locations" 
  end
  
  desc "Initialize neighbors for all city locations with tags"
  task :init_by_city_locations_with_tags do
    city    = City.find_by_name(ENV["CITY"].titleize) if ENV["CITY"]
    limit   = ENV["LIMIT"] ? ENV["LIMIT"].to_i : 2**30
    offset  = ENV["OFFSET"] ? ENV["OFFSET"].to_i : 0
    filter  = ENV["FILTER"] if ENV["FILTER"]
    sleep   = ENV["SLEEP"] ? ENV["SLEEP"].to_i : 0

    if city.blank?
      puts "*** invalid city"
      exit
    end

    puts "#{Time.now}: initializing neighbors for #{city.name} locations with tags and no existing neighbors, offset: #{offset} limit: #{limit}"

    page        = 1
    page_size   = 1000
    ids         = Location.no_neighbors.with_latlng.all(:all, :offset => offset, :limit => limit, :include => :companies, :conditions => ["city_id = ? AND companies.taggings_count > 0", city.id], :select => 'id').collect(&:id)

    puts "#{Time.now}: found #{ids.size} matching location ids"

    neighbors   = init_neighbors(ids, page, page_size, :filter => filter, :limit => limit, :sleep => sleep)

    puts "#{Time.now}: completed, added neighbors to #{neighbors} locations" 
  end
  
  def init_neighbors(ids, page, page_size, options={})
    filter    = options[:filter]
    limit     = options[:limit] ? options[:limit].to_i : 2**30
    isleep    = options[:sleep].to_i
    neighbors = 0
     
    # Note: the 'find_in_batches' method messes up the sql conditions for all nested sql calls
    until (batch_ids = ids.slice((page - 1) * page_size, page_size)).blank?
      locations = Location.find(batch_ids)
      locations.each do |location|
        if filter
          # apply filter
          next unless "#{location.id}:#{location.name}".match(/#{filter}/)
        end
        neighbors += set_location_neighbors(location)
        # check limit
        return neighbors if neighbors >= limit
        # sleep
        sleep(isleep) if isleep > 0
      end
      puts "#{Time.now}: #{page * page_size} locations processed, added neighbors to #{neighbors} locations"
      page  += 1
    end
    
    neighbors
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
  #   while !(locations = Location.with_city(city).urban_mapped.with_neighborhoods.all(:offset => (page - 1) * per_page, :limit => per_page)).blank?
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