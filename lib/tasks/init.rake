namespace :db do
  namespace :walnut do
    namespace :init do
    
      task :all  => [:areas, "db:populate:places", "db:populate:addresses", :tags, :city_zips]
    
      desc "Init areas database"
      task :areas do
        # create default areas

        @us = Country.create(:name => "United States", :code => "US")
        Area.create(:extent => @us)
        
        [{:city => "Chicago", :zip => "60654", :state => "Illinois", :code => "IL", :neighborhood => "River North"},
         {:city => "New York", :zip => "10001", :state => "New York", :code => "NY"},
         {:city => "San Francisco", :zip => "94127", :state =>  "California", :code => "CA"}].each do |hash|
          @state  = State.create(:name => hash[:state], :code => hash[:code], :country => @us)
          @city   = City.create(:name => hash[:city], :state => @state)
          @zip    = Zip.create(:name => hash[:zip], :state => @state)
          Area.create(:extent => @state)
          Area.create(:extent => @city)
          Area.create(:extent => @zip)
          
          if hash[:neighborhood]
            @neighborhood = Neighborhood.create(:name => hash[:neighborhood], :city => @city)
            Area.create(:extent => @neighborhood)
          end
        end
      
        puts "#{Time.now}: initialized #{Area.count} areas"
      end
    
      desc "Init tags by tagging each address with a city, zip, and state area"
      task :tags do
        addresses = 0
        Address.all.each do |address|
          # pick a random city
          city    = City.find(rand(City.count) + 1)
          state   = city.state
          zip     = state.zips.first # should use a city zip when this relationship is built
          country = state.country
          
          address.areas.push(city.areas.first)
          address.areas.push(zip.areas.first)
          address.areas.push(state.areas.first)
          address.areas.push(country.areas.first)

          # check for city neighborhoods
          if city.neighborhoods_count > 0
            neighborhood = city.neighborhoods.rand
            address.areas.push(neighborhood.areas.first)
          end
          
          addresses += 1
        end
        puts "#{Time.now}: tagged all #{addresses} addresses with a city, zip state area"

        # create list of addresses w/ no places
        addresses = Address.all.select { |a| a.places.size == 0 }
        
        # initialize tag list
        tags      = ['coffee', 'beer', 'soccer', 'bar', 'party', 'muffin', 'pizza']
        
        # add tags to each place, assign an addresss to each place
        places    = 0
        Place.all.each do |place|
          # pick a random address
          address = addresses.delete(addresses.rand)
          place.addresses.push(address)
          
          # pick 2 random tags and add it to the address as place tags
          picked  = pick_tags(tags, 2)
          address = place.addresses.first
          address.place_tag_list.add(picked.sort)
          address.save
          
          # place.tag_list = tags[rand(tags.size)]
          # place.save
          places += 1 
        end
        
        puts "#{Time.now}: tagged all #{places} places with an address and tag"
      end
    
      # pick n tags randomly from the tags collection
      def pick_tags(tags, n)
        picked = []
        while picked.size < n
          picked.push(tags.rand).uniq!
        end
        picked
      end
      
      desc "Initialize city to zip mappings"
      task :city_zips do
        Address.all.each do |address|
          # find address city, zip areas
          areas = address.areas.select { |area| [City, Zip].include?(area.extent.class) }
          
          # partition areas by type
          groups  = areas.partition { |area| area.extent.is_a?(City) }
          
          cities  = groups.first
          zips    = groups.last
          
          cities.each do |city_area|
            zips.each do |zip_area|
              CityZip.create(:city => city_area.extent, :zip => zip_area.extent)
            end
          end
        end
        
        puts "#{Time.now}: initialized city to zip mappings"
      end
      
    end # init
  end # walnut
end