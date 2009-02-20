namespace :localeze do
  
  namespace :init do
    task :all => ["localeze:chains:import", 
                  "localeze:import_by_city_and_state[Chicago,IL]", 
                  "localeze:chains:add_by_city_state['Chicago','IL']"]
  end
  
  desc "Import localeze tags"
  task :import_tags do
    
    puts "#{Time.now}: importing localeze tags"
    
    checked = 0
    tagged  = 0
    blank   = 0 
    
    page    = 1
    limit   = nil
    
    until (locations = Location.find(:all).paginate(:page => page, :per_page => 100)).blank?
    
      locations.each do |location|
        # track number of locations checked
        checked += 1
        
        tags = Localeze::BaseRecord.find(location.source_id).get(:tags)
        
        if tags.blank?
          LOCALEZE_LOGGER.debug("xxx location #{location.id}:#{location.locatable.name} has no localeze tags")
          blank += 1
          next
        end
        
        # build new tag list
        new_tag_list  = tags.collect { |hash| hash["tag"] }.uniq.sort
        place         = location.locatable
        cur_tag_list  = place.tag_list.sort
        
        # check if the tags have changed
        if cur_tag_list == new_tag_list
          next
        end
        
        # xxx remove all tags, then add all tags
        place.tag_list.remove(place.tag_list)
        place.save
        place.reload
        
        place.tag_list.add(new_tag_list)
        place.save
       
        tagged += 1
        
        puts "*** added tags: '#{new_tag_list.join(",")}' to place: #{place.name}"

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
  
  desc "Import localeze records"
  task :import_records_by_city_and_state, :city, :state_code do |t, args|
    city        = args.city.titleize
    state_code  = args.state_code.upcase
    
    exit if city.blank? or state_code.blank?
    
    puts "#{Time.now}: importing localeze records for #{city}:#{state_code}"
    
    # track stats
    added       = 0
    errors      = 0
    exists      = 0
    
    @country    = Country.find_by_code("US")
    page        = 1
    limit       = nil
    
    until (records = Localeze::BaseRecord.find(:all, :params => {:city => city, :state => state_code, :page => page})).blank?
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
          exit
        end
      end
      
      page += 1
    end
    
    puts "#{Time.now}: completed, #{added} added, #{exists} already imported, #{errors} errors"
  end
    
end #localeze

    