namespace :localeze do
  
  namespace :init do
    task :all => ["localeze:chains:import", 
                  "localeze:import_by_city_and_state[Chicago,IL]", 
                  "localeze:chains:add_by_city_state['Chicago','IL']"]
  end
  
  namespace :chains do
  
    desc "Import localeze chains"
    task :import do
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
    
    desc "Add localeze chains"
    task :add_by_city_and_state, :city, :state_code do |t, args|
      city        = args.city.titleize
      state_code  = args.state_code.upcase

      exit if city.blank? or state_code.blank?
      
      added = 0
      Chain.all.each do |chain|
        puts "*** chain #{chain.name}"

        # map chain to localeze chain object
        localeze_chain = Localeze::Chain.find(:first, :params => {:name => chain.name})
        next if localeze_chain.blank?
        
        # find chains in the specified city, state
        page = 1
        until (records = Localeze::BaseRecord.find(:all, :params => {:city => city, :state => state_code, :chain_id => localeze_chain.id, :page => page})).blank?
          records.each do |record|
            # map record to location
            location = Location.find_by_source_id(record)
            next if location.blank?
            
            # add chain to location place
            place = location.first.locatable
            next if place.chain
            
            place.chain = chain
            place.save
            added += 1
          end
          
          page += 1
        end
      end
    
      puts "#{Time.now}: completed, added #{added} chains to places"
    end
  end
  
  desc "Import localeze records"
  task :import_by_city_and_state, :city, :state_code do |t, args|
    city        = args.city.titleize
    state_code  = args.state_code.upcase
    
    exit if city.blank? or state_code.blank?
    
    puts "#{Time.now}: importing localeze records for #{city}:#{state_code}"
    
    # track errors
    added       = 0
    errors      = 0
    exists      = 0
    
    @country    = Country.find_by_code("US")
    
    page  = 1
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
      
        # create associated place
        place     = Place.create(:name => record.stdname)
        place.locations.push(location)
        place.reload
      
        # add a tag
        place.tag_list.add("business")
        place.save
      
        # TODO: check for chain
        
        added += 1
      end
      
      page += 1
    end
    
    puts "#{Time.now}: completed, #{added} added, #{exists} already imported, #{errors} errors"
  end
    
end #localeze

    