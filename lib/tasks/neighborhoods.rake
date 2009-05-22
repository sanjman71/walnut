namespace :neighborhoods do
  
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

    while !(locations = Location.for_city(city).urban_mapped.with_neighborhoods.all(:offset => (page - 1) * per_page, :limit => per_page)).blank?
      locations.each do |location|
        # skip locations with no street address; these map to the 'center' of the city
        # skip locations with no lat/lng coordinates
        if location.street_address.blank? or !location.mappable?
          skipped += 1
          next
        end
      
        if filter
          # apply filter
          next unless "#{location.id}:#{location.name}".match(/#{filter}/)
        end
        
        puts "#{Time.now}: *** finding neighbors for #{location.id}:#{location.name}"
      
        # find neighbors, constrained by city and distance
        attributes  = ::Search.attributes(Array(location.city))
        attributes["@geodist"] = 0.0..Neighborhood.within_neighborhood_distance_meters
        origin      = [Math.degrees_to_radians(location.lat).to_f, Math.degrees_to_radians(location.lng).to_f]
        limit       = 100
        neighbors   = Location.search(:geo => origin, :with => attributes, :without_ids => location.id, :order => "@geodist asc",  
                                      :max_matches => limit, :limit => limit)
      
        # filter out neighbors that already have neighborhoods
        neighbors   = neighbors.delete_if { |o| o.neighborhoods_count > 0 }
        
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

    puts "#{Time.now}: completed, added neighborhoods to #{added} location, #{skipped} skipped"
  end
  
  desc "Import neighborhoods from urban mapping based on city popular tags"
  task :import_from_urban_by_city_popular_tags do
    city        = City.find_by_name(ENV["CITY"].titleize) if ENV["CITY"]
    limit       = ENV["LIMIT"] ? ENV["LIMIT"].to_i : 2**30
    added       = 0
    over_limit  = false
    
    if city.blank?
      puts "*** invalid city"
      exit
    end

    puts "#{Time.now}: importing #{city.name} neighborhoods, limit #{limit}"
    
    # find popular tags
    tags = popular_tags(city, :limit => 150)

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

      locations.each do |location|
        # skip if location has already been mapped or has neighborhoods (i.e. mapped w/o using urban mapping)
        next if !location.urban_mapping_at.blank? or location.neighborhoods_count > 0

        puts "#{Time.now}: *** mapping location #{location.id}:#{location.name}"
        
        begin
          # add neighborhoods from urban mapping
          added += add_urban_neighborhoods(location)
        rescue UrbanMapping::ExceededRateLimitError
          # we're done for today
          over_limit = true
          break
        end
        
        if added >= limit
          # self imposed limit
          over_limit = true
          break
        end
        
        # throttle calls to urban mapping
        Kernel.sleep(1)
      end

      # check if we exceeded our rate limit
      break if over_limit
    end

    puts "#{Time.now}: completed, added #{added} neighborhoods"
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
    rescue Exception => e
      puts "#{Time.now}: xxx #{e.message}"
      return 0
    end
    
    puts "#{Time.now}: *** mapped location #{location.id}:#{location.name} to urban hoods #{neighborhoods.collect(&:name).join(',')}"

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
    puts "#{Time.now}: *** adding neighborhoods #{location.neighborhoods.collect(&:name).join(',')} to location #{neighbor.id}:#{neighbor.name}"

    added = 0
    location.neighborhoods.each do |neighborhood|
      next if neighbor.neighborhoods.include?(neighborhood)
      neighbor.neighborhoods.push(neighborhood)
      added += 1
    end
    added
  end
end