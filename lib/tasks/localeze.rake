namespace :localeze do
  
  namespace :init do
    task :all => ["localeze:chains:import", 
                  "localeze:import_by_city_and_state[Chicago,IL]", 
                  "localeze:chains:add_by_city_state['Chicago','IL']"]
  end
  
  desc "Import localeze categories"
  task :import_categories do
    
    puts "#{Time.now}: importing localeze categories"
    
    checked = 0
    tagged  = 0
    blank   = 0 
    
    page    = 1
    limit   = nil
    
    until (locations = Location.find(:all).paginate(:page => page, :per_page => 100)).blank?
    
      locations.each do |location|
        # track number of locations checked
        checked += 1

        categories  = Localeze::BaseRecord.find(location.source_id).get(:categories)
        groups      = []
         
        categories.each do |category|
          # map category to a tag group
          tag_groups = TagGroup.search_by_name(category['name'])
          
          # a category should match exactly 1 tag group
          next if tag_groups.size != 1
          groups += tag_groups
        end

        next if groups.blank?
        
        puts "*** groups: #{groups.collect(&:name).join(",")}"
        
        # add place/group mappings
        place = location.locatable
        groups.each do |group|
          next if group.places.include?(place)
          group.places.push(place)
          puts "*** added group: '#{group.name}' to place: #{place.name}:#{place.id}"
        end
        
        # tags = Localeze::BaseRecord.find(location.source_id).get(:tags)
        # 
        # if tags.blank?
        #   LOCALEZE_LOGGER.debug("xxx location #{location.id}:#{location.locatable.name} has no localeze tags")
        #   blank += 1
        #   next
        # end
               
        tagged += 1
        
        # check limit
        if limit and tagged >= limit
          puts "*** reached limit of #{tagged}"
          exit
        end
      end
      
      page += 1
    end
    
    puts "#{Time.now}: completed, checked #{checked} locations, tagged #{tagged} places, found #{blank} places with no tags"
  end
  
  desc "Import localeze chains"
  task :import_chains do
    added   = 0
    exists  = 0
    
    puts "#{Time.now}: importing all localeze chains"
    
    page = 1
    until (chains = Localeze::Chain.find(:all, :params => {:page => page})).blank?
      chains.each do |chain|
        if Chain.find_by_name(chain.name)
          # already exists
          exists += 1
          next
        end
        
        # add chain
        Chain.create(:name => chain.name)
        added += 1
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
        if Location.find_by_source_id(record).first
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
    
end #localeze

    