namespace :localeze do
  
  desc "Import localeze categories"
  task :import_categories do
    
    puts "#{Time.now}: importing localeze categories"
    
    checked   = 0
    mapped    = 0
    unmapped  = 0 
    
    page      = 1
    limit     = nil
    
    until (locations = Location.find(:all).paginate(:page => page, :per_page => 100)).blank?
    
      locations.each do |location|
        # track number of locations checked
        checked += 1

        categories  = Localeze::BaseRecord.find(location.source_id).get(:categories)
        groups      = []
         
        categories.each do |category|
          # map category to a tag group
          category_name = category['name'].gsub("&", "and")
          tag_groups    = TagGroup.search_name(category_name)
          
          # a category should match exactly 1 tag group
          if tag_groups.size != 1
            LOCALEZE_LOGGER.debug("#{Time.now}: xxx category #{category_name} mapped to #{tag_groups.size} tag groups")
            next
          end
          
          groups += tag_groups
        end

        if groups.blank?
          unmapped += 1
          next
        end
        
        # add place/group mappings
        place = location.locatable
        groups.each do |group|
          next if group.places.include?(place)
          group.places.push(place)
          puts "*** mapped group: '#{group.name}' to place: #{place.name}:#{place.id}"
          mapped += 1
        end
                       
        # check limit
        if limit and mapped >= limit
          puts "*** reached limit of #{mapped}"
          exit
        end
      end
      
      page += 1
    end
    
    puts "#{Time.now}: completed, checked #{checked} locations, mapped #{mapped} locations, found #{unmapped} locations with no matching categories"
  end
  
  desc "Import localeze chains"
  task :import_chains do
    added   = 0
    exists  = 0
    
    puts "#{Time.now}: importing all localeze chains"
    
    page = 1
    until (chains = Localeze::Chain.find(:all, :params => {:page => page})).blank?
      chains.each do |localeze_chain|
        if chain = Chain.find_by_name(localeze_chain.name)
          # already exists
          exists += 1
        else
          # add chain
          chain = Chain.create(:name => localeze_chain.name)
          added += 1
        end
        
        puts "#{Time.now}: importing chain info for #{chain.name}"
        records = Localeze::Chain.find(localeze_chain.id).get(:records)
        # puts "*** records: #{records}"
        records.each do |record_hash|
          # map localeze id to a location and place
          localeze_id = record_hash['id']
          location    = Location.find_by_source_id(localeze_id).first
          place       = location.locatable if location
          
          # check for valid location and place
          next if location.blank? or place.blank?
          
          if place.chain.blank?
            puts "*** chain: #{chain.name}, record: #{localeze_id}, mapped to location: #{location.id}, place: #{place.name}"
            place.chain = chain
            place.save
          end
        end
      end
      
      page += 1
    end
      
    puts "#{Time.now}: completed, added #{added} chains, #{exists} already imported"
  end
  
  desc "Import localeze records, by city and state, or by offset and limit"
  task :import_records do |t|
    
    # default page parameters
    page        = 1
    per_page    = 100
    
    if ENV["CITY"] and ENV["STATE"]
      city        = ENV["CITY"].titleize
      state_code  = ENV["STATE"].upcase
      params      = {:city => city, :state => state_code, :page => page, :per_page => per_page}
      
      puts "#{Time.now}: importing localeze records for #{city}:#{state_code}"
    elsif ENV["OFFSET"] and ENV["LIMIT"]
      offset      = ENV["OFFSET"].to_i
      limit       = ENV["LIMIT"].to_i
      params      = {:offset => offset, :limit => [per_page, limit].min} # get records in smaller chunks

      puts "#{Time.now}: importing #{limit} localeze records starting at offset #{offset}"
    else
      puts "invalid arguments"
      exit
    end
    
    # track stats
    added       = 0
    errors      = 0
    exists      = 0
    
    @country    = Country.find_by_code("US")
    
    until (records = Localeze::BaseRecord.find(:all, :params => params)).blank?
      records.each do |record|
        # check if record has already been imported
        if Location.find_by_source(record).first
          # record has already been imported
          exists += 1
          next
        end
      
        # find state
        @state = State.find_by_code(record.state)
      
        if @state.blank?
          # invalid state
          errors += 1
          next
        end
        
        if record.city.blank? or record.zip.blank?
          errors += 1
          next
        end
        
        begin
          # get city if it exists, or validate and create if it doesn't
          @city = @state.cities.find_by_name(record.city) || Locality.validate(@state, "city", record.city)
        rescue Exception
          # log exception
          @city = nil
        end
      
        if @city.blank?
          errors += 1
          next
        end

        puts "id: #{record.id}, class: #{record.class}, name: #{record.stdname}, city: #{record.city}, state: #{record.state}, zip: #{record.zip}, address: #{record.street_address}"

        begin
          # get zip if it exists, or validate and create if it doesn't
          @zip = @state.zips.find_by_name(record.zip) || Locality.validate(@state, "zip", record.zip)
        rescue Exception
          # log exception
          @zip = nil
        end
        
        if @zip.blank?
          errors += 1
          next
        end
       
        # create location
        options   = {:name => "Work", :street_address => record.street_address, :city => @city, :state => @state, :zip => @zip, :country => @country}
        options.merge!(:source_id => record.id, :source_type => record.class.to_s)
        options.merge!(:lat => record.latitude, :lng => record.longitude) if record.mappable?
        location  = Location.create(options)
      
        # create place
        place     = Place.create(:name => record.stdname)
        place.locations.push(location)
        place.reload
      
        # check for a phonenumber
        if record.phone_number
          # add phone number
          phone_number = PhoneNumber.create(:name => "Work", :number => record.phone_number)
          place.phone_numbers.push(phone_number)
        end
        
        # check for chain
        if record.chain_id > 0 and localeze_chain = Localeze::Chain.find(record.chain_id)
          # find local chain object
          chain = Chain.find_by_name(localeze_chain.name)
          # add chain
          place.chain = chain
          place.save
        end
        
        added += 1
        
        # check limit
        if limit and added >= limit
          puts "*** reached limit of #{added}"
          puts "#{Time.now}: completed, #{added} added, #{exists} already imported, #{errors} errors"
          exit
        end
      end
      
      if offset
        # increment offset
        params[:offset] = params[:offset] + [per_page, limit].min
      else
        # increment page
        params[:page]   = params[:page] + 1
      end
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

    