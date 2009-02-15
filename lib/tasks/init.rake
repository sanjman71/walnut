namespace :db do
  namespace :walnut do
    namespace :init do
    
      task :all => [:localities, :locations, "db:populate:places", :tags, :chains, :city_zips]
    
      desc "Init default countries, states, cities, zips, neighborhoods."
      task :localities do
        # create default localities

        @us = Country.create(:name => "United States", :code => "US")
        
        [{:city => "Chicago", :zip => "60654", :state => "Illinois", :code => "IL", :neighborhood => "River North"},
         {:city => "New York", :zip => "10001", :state => "New York", :code => "NY"},
         {:city => "San Francisco", :zip => "94127", :state =>  "California", :code => "CA"}].each do |hash|
          @state  = State.create(:name => hash[:state], :code => hash[:code], :country => @us)
          @city   = City.create(:name => hash[:city], :state => @state)
          @zip    = Zip.create(:name => hash[:zip], :state => @state)
          
          if hash[:neighborhood]
            @neighborhood = Neighborhood.create(:name => hash[:neighborhood], :city => @city)
          end
        end
      
        puts "#{Time.now}: initialized default countries, states, cities, zips, and neighborhoods"
      end
    
      desc "Initialize nearby cities"
      task :nearby_cities do
        @cities = [{:state => 'Illinois', :city => 'Naperville'},
                   {:state => 'Illinois', :city => 'Aurora'}]
                   
        @cities.each do |hash|
          # find state
          @state = State.find_by_name(hash[:state])
          next if @state.blank?
          
          # find or create city
          @city = @state.cities.find_by_name(hash[:city]) || City.create(:name => hash[:city], :state => @state)
          @city.geocode_latlng
        end
        
        puts "#{Time.now}: initialized nearby cities"
      end
      
      desc "Init locations."
      task :locations do |t|

        @chicago_streets  = [{:streets => ["200 W Grand Ave", "100 W Grand Ave", "70 W Erie St", "661 N Clark St", "415 N Milwaukee Ave"], 
                              :city => "Chicago"}]
        @new_york_streets = [{:streets => ["80 Wall St", "135 Front St", "150 Water St", "27 William St", "88 Pine St"], 
                              :city => "New York"}]
        @sf_streets       = [{:streets => ["1298 Howard St", "609 Mission St", "200 S Spruce Ave", "215 Harbor Way", "170 Mitchell Ave"], 
                              :city => "San Francisco"}]
        count             = 0
        
        (@chicago_streets + @new_york_streets + @sf_streets).each do |street_hash|
          streets = street_hash[:streets]
          city    = City.find_by_name(street_hash[:city].titleize)
          state   = city.state
          zip     = state.zips.first # should use a city zip when this relationship is built
          country = state.country
          
          streets.each do |street|
            location = Location.create(:name => "Work", :street_address => street, :city => city, :state => state, :zip => zip, :country => country)
            count   += 1
          end
        end
        
        puts "#{Time.now}: added #{count} location"
      end    
    
      desc "Init tags by tagging each address with a city, zip, and state locality"
      task :tags do
        # find list of locations w/ no places
        locations = Location.all.select { |a| a.locatable.nil? }
        
        # initialize tag list
        tags      = ['coffee', 'beer', 'soccer', 'bar', 'party', 'muffin', 'pizza']
        
        # assign an addresss to each place, and add tags to the location/place
        places    = 0
        Place.all.each do |place|
          # stop when there are no more locations
          break if locations.empty?
          
          # pick some random tags for the place
          picked = pick_tags(tags, 3)
          place.tag_list.add(picked.sort)
          place.save
          
          # pick a random address
          location = locations.delete(locations.rand)
          place.locations.push(location)
          
          # pick some random tags, add them to the address as place tags
          # picked   = pick_tags(tags, 3)
          # location = place.locations.first
          # location.place_tag_list.add(picked.sort)
          # location.save
          
          places += 1 
        end
        
        puts "#{Time.now}: tagged #{places} places with a location and tags"
      end
    
      # pick n tags randomly from the tags collection
      def pick_tags(tags, n)
        picked = []
        while picked.size < n
          picked.push(tags.rand).uniq!
        end
        picked
      end
      
      desc "Initialize chain stores"
      task :chains do
        chains = [{:name => "McDonalds", :tags => ["burgers", "greasy", "fries"]},
                  {:name => "Starbucks", :tags => ["coffee", "tea", "wifi"]}
                 ]
        
        chains.each do |hash|
          name  = hash[:name]
          chain = Chain.create(:name => name)
          
          # create chain places and locations
          
          place = Place.create(:name => name)
          chain.places.push(place)

          # add place tags
          place.tag_list.add(hash[:tags])
          place.save
          
          # create an address in each city
          City.all.each do |city|
            state     = city.state
            country   = state.country
            location  = Location.create(:name => "Work", :city => city, :state => state, :country => country)
            place.locations.push(location)
          end
        end
        
        puts "#{Time.now}: initialized chain stores #{chains.collect{ |h| h[:name]}.join(",")}"
      end
      
      desc "Initialize city to zip mappings"
      task :city_zips do
        Location.all.each do |location|
          # find location city, zip localities
          localities = location.localities.select { |locality| [City, Zip].include?(locality.class) }
          
          # partition areas by type
          groups  = localities.partition { |locality| locality.is_a?(City) }
          
          cities  = groups.first
          zips    = groups.last
          
          cities.each do |city_locality|
            zips.each do |zip_locality|
              CityZip.create(:city => city_locality, :zip => zip_locality)
            end
          end
        end
        
        puts "#{Time.now}: initialized city to zip mappings"
      end
      
    end # init
  end # walnut
end