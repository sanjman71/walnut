namespace :neighborhoods do
  
  # desc "Remove neighborhoods from locations with no street address"
  # task :remove_from_locations_with_no_street_address do
  #   location_ids = Location.with_neighborhoods.no_street_address.all(:select => 'id').collect(&:id)
  #   
  #   puts "#{Time.now}: found #{location_ids.size} matching locations"
  #   
  #   location_ids.each do |id|
  #     location = Location.find(id)
  #     
  #     # remove all location neighborhoods
  #     location.neighborhoods.each do |hood|
  #       location.neighborhoods.delete(hood)
  #     end
  #   end
  #   
  #   puts "#{Time.now}: completed"
  # end
  
  desc "Print neighborhood stats"
  task :stats do
    
    # find cities with neighborhoods
    cities = City.with_neighborhoods.order_by_density.all(:limit => 10)

    puts "#{Time.now}: found top #{cities.size} cities with neighborhoods"

    cities.each do |city|
      city_locations_with_hoods   = Location.with_city(city).with_neighborhoods.count
      city_locations_hoodable     = Location.with_city(city).with_street_address.count
      city_locations_hoods_ratio  = city_locations_with_hoods.to_f / city_locations_hoodable.to_f
      puts "#{Time.now}: city: #{city.name}, hoods/hoodable: #{city_locations_with_hoods}/#{city_locations_hoodable}, ratio: #{city_locations_hoods_ratio}"
    end
    
    puts "#{Time.now}: completed"
  end
  
  desc "Import neighborhoods based on proximity to locations with neighborhoods"
  task :import_by_city_proximity do
    city          = City.find_by_name(ENV["CITY"].titleize) if ENV["CITY"]
    limit         = ENV["LIMIT"] ? ENV["LIMIT"].to_i : 2**30
    filter        = ENV["FILTER"] if ENV["FILTER"]
    per_page      = 10
    page          = 1
    skipped       = 0
    added         = 0

    if city.blank?
      puts "*** invalid city"
      exit
    end

    # find locations in the specified city that have been urban mapped, order by locations most recently mapped
    location_ids  = Location.with_city(city).urban_mapped.with_neighborhoods.all(:select => "id", :order => "urban_mapping_at DESC").collect(&:id)
    
    puts "#{Time.now}: found #{location_ids.size} urban mapped locations in #{city.name}"
    
    while !(batch_ids = location_ids.slice((page - 1) * per_page, per_page)).blank?
      locations = Location.find(batch_ids)
      locations.each do |location|
        # skip locations with no street address; these map to the 'center' of the city
        # skip locations with no lat/lng coordinates
        if !location.neighborhoodable? or !location.mappable?
          skipped += 1
          next
        end
      
        if filter
          # apply filter
          next unless "#{location.id}:#{location.name}".match(/#{filter}/)
        end
        
        puts "#{Time.now}: *** finding neighbors for #{location.id}:#{location.company_name}"
      
        # find neighbors, constrained by city and distance
        attributes  = ::Search.attributes(Array(location.city))
        attributes["@geodist"] = 0.0..Neighborhood.within_neighborhood_distance_meters
        origin      = [Math.degrees_to_radians(location.lat).to_f, Math.degrees_to_radians(location.lng).to_f]
        limit       = 200
        neighbors   = Location.search(:geo => origin, :with => attributes, :without_ids => location.id, :order => "@geodist asc",  
                                      :max_matches => limit, :limit => limit)
      
        # filter out neighbors that already have neighborhoods or that are not neighborhoodable
        neighbors   = neighbors.delete_if { |o| o.neighborhoods_count > 0 or !o.neighborhoodable? }
        
        puts "#{Time.now}: *** found #{neighbors.size} hood-less neighbors within #{Neighborhood.within_neighborhood_distance_miles} miles"
        
        neighbors.each do |neighbor|

          # reload object and (re-)check neighborhoods_count
          neighbor.reload
          if neighbor.neighborhoods_count > 0
            next
          end
          
          # puts "#{Time.now}: *** neighbor #{neighbor.id}:#{neighbor.name}:#{neighbor.street_address}"

          # add locations' neighborhoods to neighbor
          add_neighborhoods_to_neighbor(location, neighbor)
          added += 1
        end
      end
      
      page += 1
    end

    puts "#{Time.now}: completed, added neighborhoods to #{added} locations, #{skipped} skipped"
  end

  desc "Import neighborhoods from urban mapping from city locations"
  task :import_from_urban_by_city_locations do
    city        = City.find_by_name(ENV["CITY"].titleize) if ENV["CITY"]
    limit       = ENV["LIMIT"] ? ENV["LIMIT"].to_i : UrbanMapping.max_requests_per_day
    
    if city.blank?
      puts "*** invalid city"
      exit
    end

    puts "#{Time.now}: importing #{city.name} neighborhoods using city neighborhoodable locations, limit #{limit}"
  
    # find neighborhoodable city locations with no neighborhoods and not mapped by urban
    ids = Location.with_city(city).with_street_address.not_urban_mapped.no_neighborhoods.all(:select => 'id').collect(&:id)
    
    puts "#{Time.now}: found #{ids.size} matching location ids"

    added     = 0
    page      = 1
    page_size = 1000
    
    while !(batch_ids = ids.slice((page - 1) * page_size, page_size)).blank?
      locations = Location.find(batch_ids)
      added    += add_neighborhoods_to_locations(locations, :limit => limit)
      break if added >= limit
      page     += 1
    end

    puts "#{Time.now}: completed, added #{added} neighborhoods"
  end
  
  desc "Import neighborhoods from urban mapping from city locations with tags"
  task :import_from_urban_by_city_locations_with_tags do
    city        = City.find_by_name(ENV["CITY"].titleize) if ENV["CITY"]
    limit       = ENV["LIMIT"] ? ENV["LIMIT"].to_i : UrbanMapping.max_requests_per_day
    
    if city.blank?
      puts "*** invalid city"
      exit
    end

    puts "#{Time.now}: importing #{city.name} neighborhoods using city neighborhoodable locations with tags, limit #{limit}"
  
    # find neighborhoodable city locations with tags but no neighborhoods and not mapped by urban
    ids = Location.with_city(city).with_street_address.not_urban_mapped.no_neighborhoods.all(:joins => :companies, :conditions => "companies.taggings_count > 0", :select => 'locations.id').collect(&:id)
    
    puts "#{Time.now}: found #{ids.size} matching location ids"
    
    added     = 0
    page      = 1
    page_size = 1000
    
    while !(batch_ids = ids.slice((page - 1) * page_size, page_size)).blank?
      locations = Location.find(batch_ids)
      added    += add_neighborhoods_to_locations(locations, :limit => limit)
      break if added >= limit
      page     += 1
    end

    puts "#{Time.now}: completed, added #{added} neighborhoods"
  end
  
  desc "Import neighborhoods from urban mapping based on city popular tags"
  task :import_from_urban_by_city_popular_tags do
    city        = City.find_by_name(ENV["CITY"].titleize) if ENV["CITY"]
    limit       = ENV["LIMIT"] ? ENV["LIMIT"].to_i : 300 # 300 is max requests per day allowed with free api
    tag_limit   = ENV["TAG_LIMIT"] ? ENV["TAG_LIMIT"].to_i : 200
    added       = 0
    
    if city.blank?
      puts "*** invalid city"
      exit
    end

    puts "#{Time.now}: importing #{city.name} neighborhoods using popular tags, tag limit #{tag_limit}, limit #{limit}"
    
    # find popular tags
    tags = popular_tags(city, :limit => tag_limit)

    tags.each do |tag|
      # find locations tagged with 'tag'

      puts "#{Time.now}: *** tag: #{tag.name}"
      
      hash        = Search.query(tag.name)
      query       = hash[:query_or]
      attributes  = Search.attributes(city)
      klasses     = [Location]
      locations   = ThinkingSphinx::Search.search(query, :classes => klasses, :with => attributes,
                                                  :match_mode => :extended, :page => 1, :per_page => 5,
                                                  :order => :popularity, :sort_mode => :desc)

      add_limit   = limit - added
      added       += add_neighborhoods_to_locations(locations, :limit => add_limit)
      break if added >= limit
    end

    puts "#{Time.now}: completed, added #{added} neighborhoods"
  end
  
  desc "Import neighborhoods from urban mapping based on city event venues"
  task :import_from_urban_by_city_event_venues do
    city        = City.find_by_name(ENV["CITY"].titleize) if ENV["CITY"]
    limit       = ENV["LIMIT"] ? ENV["LIMIT"].to_i : 300 # 300 is max requests per day allowed with free api
    added       = 0
    
    if city.blank?
      puts "*** invalid city"
      exit
    end

    puts "#{Time.now}: importing #{city.name} neighborhoods for event venues, limit #{limit}"
  
    hash          = Search.query("events:1")
    # @query_raw    = @hash[:query_raw]
    # @query_or     = @hash[:query_or]
    # @query_and    = @hash[:query_and]
    # @fields       = @hash[:fields]
    attributes    = hash[:attributes] || Hash.new
    attributes    = Search.attributes(city).update(attributes)

    per_page      = 200
    locations     = Location.search(:with => attributes, :match_mode => :extended, :page => 1, :per_page => per_page, :max_matches => per_page,
                                    :order => :popularity, :sort_mode => :desc)

    added         = add_neighborhoods_to_locations(locations, :limit => limit)
    
    puts "#{Time.now}: completed, added #{added} neighborhoods"
  end
  
  def add_neighborhoods_to_locations(locations, options={})
    limit = options[:limit] ? options[:limit].to_i : 2**30
    added = 0
    
    locations.each do |location|
      # skip if location has already been mapped or has neighborhoods (i.e. mapped w/o using urban mapping)
      next if !location.urban_mapping_at.blank? or location.neighborhoods_count > 0

      puts "#{Time.now}: *** mapping location #{location.id}:#{location.company_name}"

      begin
        # add neighborhoods from urban mapping
        added += add_urban_neighborhoods(location)
      rescue UrbanMapping::ExceededRateLimitError => e
        # we're done for today
        raise e
        # return added
      rescue Exception => e
        puts "#{Time.now}: xxx whoops: #{e.message}"
        return added
      end
      
      if added >= limit
        # self imposed limit
        return added
      end
      
      # throttle calls to urban mapping
      Kernel.sleep(1)
    end
    
    added
  end
  
  def popular_tags(city, options={})
    # build tag cloud from location and event objects
    tag_limit = options[:limit] ? options[:limit].to_i : 150
    facets    = Location.facets(:with => ::Search.attributes(city), :facets => "tag_ids", :limit => tag_limit, :max_matches => tag_limit)
    tags      = Search.load_from_facets(facets, Tag)

    # tag_limit = 30
    # facets    = Event.facets(:with => Search.attributes(city), :facets => "tag_ids", :limit => tag_limit, :max_matches => tag_limit)
    # tags      += Search.load_from_facets(facets, Tag)

    # return sorted tags collection
    # tags.sort_by { |o| o.name }
    
    tags
  end
  
  def add_urban_neighborhoods(location)
    begin
      neighborhoods = UrbanMapping::Neighborhood.find_all(location)
    rescue UrbanMapping::ExceededRateLimitError => e
      puts "#{Time.now}: xxx #{e.message}"
      raise e
    rescue Exception => e
      puts "#{Time.now}: xxx #{e.message}"
      return 0
    end
    
    puts "#{Time.now}: *** mapped location #{location.id}:#{location.company_name} to urban hoods #{neighborhoods.collect(&:name).join(',')}"

    added = 0
    
    # add neighborhoods
    neighborhoods.each do |neighborhood|
      next if location.neighborhoods.include?(neighborhood)
      location.neighborhoods.push(neighborhood)
      added += 1
    end

    # update timestamp
    location.update_attribute(:urban_mapping_at, Time.now)

    added
  end
  
  def add_neighborhoods_to_neighbor(location, neighbor)
    puts "#{Time.now}: *** adding neighborhoods #{location.neighborhoods.collect(&:name).join(',')} to location #{neighbor.id}:#{neighbor.company_name}"

    added = 0
    location.neighborhoods.each do |neighborhood|
      next if neighbor.neighborhoods.include?(neighborhood)
      neighbor.neighborhoods.push(neighborhood)
      added += 1
    end
    added
  end
end
