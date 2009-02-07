namespace :db do
  namespace :walnut do
    namespace :init do
    
      task :all  => [:areas, "db:populate:places", "db:populate:addresses", :tags]
    
      desc "Init areas database"
      task :areas do
        # create default areas

        @us = Country.create(:name => "United States", :code => "US")
        Area.create(:extent => @us)
        
        [{:city => "Chicago", :state => "Illinois", :code => "IL"},
         {:city => "New York", :state => "New York", :code => "NY"},
         {:city => "San Francisco", :state =>  "California", :code => "CA"}].each do |hash|
          @state  = State.create(:name => hash[:state], :code => hash[:code], :country => @us)
          @city   = City.create(:name => hash[:city], :state => @state)
          Area.create(:extent => @state)
          Area.create(:extent => @city)
        end
      
        puts "#{Time.now}: initialized #{Area.count} areas"
      end
    
      desc "Init tags by tagging each address with a city and state area"
      task :tags do
        addresses = 0
        Address.all.each do |address|
          # pick a random city
          city    = City.find(rand(City.count) + 1)
          state   = city.state
          country = state.country
          
          address.areas.push(city.areas.first)
          address.areas.push(state.areas.first)
          address.areas.push(country.areas.first)
          address.save
                    
          addresses += 1
        end
        puts "#{Time.now}: tagged all #{addresses} addresses with a city and state areas, and a place"

        # create address list of objects w/ no places
        addresses = Address.all.select { |a| a.places.size == 0 }
        
        # initialize tag list
        tags      = ['coffee', 'beer', 'soccer']
        
        # add tags to each place, assign an addresss to each place
        places    = 0
        Place.all.each do |place|
          # pick a random address
          address = addresses.delete(addresses.rand)
          place.addresses.push(address)
          
          # pick a random tag and add it to the address as a place tag
          tag     = tags[rand(tags.size)]
          address = place.addresses.first
          address.place_tag_list = tag
          address.save
          
          # place.tag_list = tags[rand(tags.size)]
          # place.save
          places += 1 
        end
        puts "#{Time.now}: tagged all #{places} places with an address and tag"
      end
    
    end # init
  end # walnut
end