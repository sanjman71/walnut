namespace :db do
  namespace :walnut do
    namespace :init do
    
      task :all  => [:areas, :addresses, "db:populate:places", :tags, :city_zips]
    
      desc "Init areas database"
      task :areas do
        # create default areas

        @us = Country.create(:name => "United States", :code => "US")
        Area.create(:extent => @us)
        
        [{:city => "Chicago", :zip => "60654", :state => "Illinois", :code => "IL", :neighborhood => "River North", 
          :streets => ["200 W Grand Ave", "100 W Grand Ave", "70 W Erie St"]},
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
    
      desc "Init addresses."
      task :addresses do |t|

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
            address = Address.create(:name => "Work", :street_address => street, :city => city, :state => state, :zip => zip, :country => country)
            count   += 1
          end
        end
        
        puts "#{Time.now}: added #{count} addresses"
      end    
    
      desc "Init tags by tagging each address with a city, zip, and state area"
      task :tags do
        # find list of addresses w/ no places
        addresses = Address.all.select { |a| a.places.size == 0 }
        
        # initialize tag list
        tags      = ['coffee', 'beer', 'soccer', 'bar', 'party', 'muffin', 'pizza']
        
        # assign an addresss to each place, and add tags to the address/place
        places    = 0
        Place.all.each do |place|
          # stop when there are no more addresses
          break if addresses.empty?
          
          # pick a random address
          address = addresses.delete(addresses.rand)
          place.addresses.push(address)
          
          # pick some random tags, add them to the address as place tags
          picked  = pick_tags(tags, 3)
          address = place.addresses.first
          address.place_tag_list.add(picked.sort)
          address.save
          
          places += 1 
        end
        
        puts "#{Time.now}: tagged #{places} places with an address and tag"
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