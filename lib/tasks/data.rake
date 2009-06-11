namespace :data do
  
  # Performance: ~ 1 hour
  desc "Import localeze categories and attributes as tags and tag groups"
  task :import_tags do
    
    puts "#{Time.now}: importing localeze categories and attributes"
    
    checked   = 0
    mapped    = 0
    unmapped  = 0 
    tagged    = 0
    taggs     = 0
    skipped   = 0
    
    # intialiaze page parameters, limit
    page          = ENV["PAGE"] ? ENV["PAGE"].to_i : 1
    per_page      = ENV["PER_PAGE"] ? ENV["PER_PAGE"].to_i : 1000
    limit         = ENV["LIMIT"] ? ENV["LIMIT"].to_i : 2**30
    offset        = (page - 1) * per_page
     
    # initialize conditions hash
    conditions    = {:tag_groups_count => 0}
    
    # find places with no tag groups
    until (places = Place.find(:all, :conditions => conditions, :include => :locations, :offset => offset, :limit => per_page)).blank?
      places.collect(&:locations).flatten.each do |location|
        # track number of locations checked
        checked     += 1

        # make sure location is from localeze, or has a source
        next unless !location.location_sources.blank?

        place       = location.place
        record      = Localeze::BaseRecord.find(location.location_sources.first.source_id)
        categories  = record.categories
        attributes  = record.attributes
        groups      = []
         
        attributes.each do |attribute|
          group_name  = attribute['group_name']
          attr_name   = attribute['name']
          
          tags_list   = Localeze::TagFilter.to_tags(group_name, attr_name)

          if tags_list.blank?
            # puts "*** skipping attribute, group: #{group_name}, name: #{attr_name} - place:#{place.name}"
            DATA_TAGS_LOGGER.debug("xxx skipping attribute, group: #{group_name}, name: #{attr_name} - place:#{place.name}")
            skipped += 1
          end

          tags_list.each do |tag_name|
            puts "*** tagging #{place.name} with #{tag_name}"
            place.tag_list.add(tag_name)
            place.save
            tagged += 1
          end
        end

        categories.each do |category|
          # map category to a tag group
          category_name = category['name'].gsub("&", "and")
          tag_groups    = TagGroup.search_name(category_name)

          if category_name == "Health Services"
            # special case, find exact match
            tag_groups  = TagGroup.find_all_by_name(category_name)
          end
          
          # create tag group if there are 0 matches
          if tag_groups.size == 0
            tag_groups  = [TagGroup.create(:name => category_name)]
          end
          
          # a category should match exactly 1 tag group
          if tag_groups.size != 1
            DATA_TAGS_LOGGER.debug("#{Time.now}: xxx category #{category_name} mapped to #{tag_groups.size} tag groups")
            next
          end
          
          groups += tag_groups
        end

        if groups.blank?
          unmapped += 1
          next
        end
        
        # add place/group mappings
        place = location.place
        groups.each do |group|
          next if group.places.include?(place)
          group.places.push(place)
          # puts "*** mapped group: '#{group.name}' to place: #{place.name}:#{place.id}"
          mapped += 1
        end
                       
        # check limit
        if mapped >= limit
          puts "*** reached limit of #{mapped}"
          exit
        end
      end
      
      page   += 1
      offset  = (page - 1) * per_page
    end
    
    puts "#{Time.now}: completed, checked #{checked} locations, mapped #{mapped} locations, found #{unmapped} locations with no matching categories"
  end
  
  desc "Import localeze chains"
  task :import_chains do
    # intialiaze page parameters, limit
    page          = ENV["PAGE"] ? ENV["PAGE"].to_i : 1
    per_page      = ENV["PER_PAGE"] ? ENV["PER_PAGE"].to_i : 100
    limit         = ENV["LIMIT"] ? ENV["LIMIT"].to_i : 2**30
    offset        = (page - 1) * per_page
     
    # initialize conditions hash
    conditions    = {}
    
    added   = 0
    exists  = 0
    places  = 0
    
    puts "#{Time.now}: importing all localeze chains"
    
    page = 1
    until (chains = Localeze::Chain.find(:all, :conditions => conditions, :limit => per_page, :offset => offset)).blank?
      chains.each do |localeze_chain|
        if chain = Chain.find_by_name(localeze_chain.name)
          # already exists
          exists += 1
        else
          # add chain
          chain = Chain.create(:name => localeze_chain.name)
          added += 1
        end
        
        # find all localeze records for this chain
        puts "#{Time.now}: importing chain info for #{chain.name}"
        records = Localeze::Chain.find(localeze_chain.id).get(:records)
        
        records.each do |record_hash|
          # map localeze id to a location and place
          localeze_id = record_hash['id']
          source      = LocationSource.find_by_source_id(localeze_id).first
          location    = source.location if source
          place       = location.place if location
          
          # check for valid location and place
          next if location.blank? or place.blank?

          # the place exists, add chain if its not already mapped
          if place.chain.blank?
            puts "*** chain: #{chain.name}, record: #{localeze_id}, mapped to location: #{location.id}, place: #{place.name}"
            place.chain = chain
            place.save
            places += 1
          end
        end
      end
      
      # increment page and offset
      page  += 1
      offset = (page - 1) * per_page
    end
      
    puts "#{Time.now}: completed, added #{added} chains, #{exists} already imported, and mapped #{places} places to chains"
  end
  
  # Performance:
  #  - import 10K records in ~14 minutes
  #  - import 250K records in ~240 minutes
  #  - import 437K records in ~450 minutes
  desc "Import localeze records, by city and state or cbsa"
  task :import_records do |t|
    
    # intialiaze page parameters, limit
    page          = ENV["PAGE"] ? ENV["PAGE"].to_i : 1
    per_page      = ENV["PER_PAGE"] ? ENV["PER_PAGE"].to_i : 1000
    limit         = ENV["LIMIT"] ? ENV["LIMIT"].to_i : 2**30
    filter        = ENV["FILTER"] if ENV["FILTER"]
    offset        = (page - 1) * per_page
     
    # initialize conditions hash
    conditions    = {}
    
    if ENV["CITY"] and ENV["STATE"]
      city        = ENV["CITY"].titleize
      state_code  = ENV["STATE"].upcase

      # validate city and state
      state       = State.find_by_code(state_code)
      city        = state.cities.find_by_name(city) unless state.blank?
      
      if state.blank? or city.blank?
        puts "#{Time.now}: invalid city or state"
        exit
      end

      # build conditions for city and state
      conditions.update({:city => city.name, :state => state.code})
      
      puts "#{Time.now}: importing localeze records for #{city}:#{state_code}, limit: #{limit}, page: #{page}, per page: #{per_page}"
    elsif ENV["CBSA"]
      cbsa  = ENV["CBSA"].to_s.strip

      # build conditions for cbsa
      conditions.update({:cbsa => cbsa})

      puts "#{Time.now}: importing localeze records for cbsa #{cbsa}, limit: #{limit}, page: #{page}, per page: #{per_page}"
    else
      # import all records
      puts "#{Time.now}: importing all localeze records, limit: #{limit}, page: #{page}, per page: #{per_page}"
    end
    
    # track stats
    added       = 0
    errors      = 0
    exists      = 0
    
    @country    = Country.find_by_code("US")
    
    # find all matching record ids
    record_ids  = Localeze::BaseRecord.find(:all, :select => 'id', :conditions => conditions)
    
    puts "#{Time.now}: found #{record_ids.size} matching record ids"
    
    # load records in batches
    until (batch_ids = record_ids.slice(offset, per_page)).blank?
      records = Localeze::BaseRecord.find(batch_ids)
      
      puts "#{Time.now}: processing batch #{offset}"
      
      records.each do |record|
        # check if record has already been imported
        if LocationSource.find_by_source(record).first
          # record has already been imported
          exists += 1
          next
        end
      
        if filter
          # apply filter
          next unless record.stdname.match(/#{filter}/)
        end
        
        # find state
        @state  = @country.states.find_by_code(record.state)
      
        if @state.blank?
          # invalid state
          errors += 1
          DATA_ERROR_LOGGER.debug("#{Time.now}: xxx record:#{record.id} invalid state #{record.state}")
          next
        end
        
        if record.city.blank? or record.zip.blank?
          errors += 1
          DATA_ERROR_LOGGER.debug("#{Time.now}: xxx record:#{record.id} missing city or zip")
          next
        end
        
        # fix localeze errors, and there are lots of them
        record.normalize_city_and_state
        
        begin
          # get city if it exists, or validate and create if it doesn't
          @city = @state.cities.find_by_name(record.city) || Locality.validate(@state, "city", record.city)
        rescue Exception
          # log exception
          @city = nil
          DATA_ERROR_LOGGER.debug("#{Time.now}: xxx record:#{record.id} could not validate city:#{record.city} in state:#{@state.name}")
        end
      
        if @city.blank?
          errors += 1
          next
        end

        # puts "id: #{record.id}, class: #{record.class}, name: #{record.stdname}, city: #{record.city}, state: #{record.state}, zip: #{record.zip}, address: #{record.street_address}"

        begin
          # get zip if it exists, or validate and create if it doesn't
          @zip = @state.zips.find_by_name(record.zip) || Locality.validate(@state, "zip", record.zip)
        rescue Exception
          # log exception
          @zip = nil
          DATA_ERROR_LOGGER.debug("#{Time.now}: xxx record:#{record.id} could not validate zip:#{record.zip} in state:#{@state.name}")
        end
        
        if @zip.blank?
          errors += 1
          next
        end

        # look for an existing location with the same street address and name
        locations = Location.find(:all, :conditions => {:city_id => @city.id, :street_address => record.street_address}, :include => :places)
        location  = locations.select { |l| l.place_name == record.stdname }.first
        
        if location
          # found a matching location, so use it
          place = location.place
        else
          # create location
          options   = {:street_address => record.street_address, :city => @city, :state => @state, :zip => @zip, :country => @country}
          options.merge!(:lat => record.latitude, :lng => record.longitude) if record.mappable?
          location  = Location.create(options)

          # create place
          place     = Place.create(:name => record.stdname)
          place.locations.push(location)
          
          # reload
          place.reload
          location.reload
        end
        
        # add location source
        location.location_sources.push(LocationSource.new(:source_id => record.id, :source_type => record.class.to_s))
        
        # check for a phonenumber
        if record.phone_number
          # add phone number to location
          location.phone_numbers.push(PhoneNumber.new(:name => "Work", :number => record.phone_number))
        end
        
        # check for chain
        if !record.chain_id.blank? and localeze_chain = Localeze::Chain.find_by_id(record.chain_id)
          # find or create local chain object
          chain = Chain.find_by_name(localeze_chain.name) || Chain.create(:name => localeze_chain.name)
          
          if !place.chain?
            # add chain
            place.chain = chain
            place.save
          end
        end
        
        added += 1
        
        if (added % 1000) == 0
          puts "#{Time.now}: *** added #{added} records"
        end
        
        # check limit
        if limit and added >= limit
          puts "#{Time.now}: *** reached limit of #{added}"
          puts "#{Time.now}: completed, #{added} added, #{exists} already imported, #{errors} errors"
          exit
        end
      end
      
      # increment page and offset
      page  += 1
      offset = (page - 1) * per_page
    end
    
    puts "#{Time.now}: completed, #{added} added, #{exists} already imported, #{errors} errors"
  end
    
  desc "Import tag groups from the localeze log"
  task :import_tag_groups_from_localeze_log do |t|
  
    file    = "#{RAILS_ROOT}/log/localeze.log"
    groups  = []
    
    IO.readlines(file).each do |line|
      if line.match(/xxx category ([\w\s-]+) mapped/)
        puts "tag group: " + $1
        groups.push($1)
      end
    end
    
    # add unique tag groups
    groups.uniq!
    groups.each do |group|
      TagGroup.create(:name => group)
    end
    
    puts "#{Time.now}: completed, added #{groups.size} tag groups"
  end
  
end #localeze

    