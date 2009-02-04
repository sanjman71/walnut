namespace :db do
  namespace :walnut do
    namespace :init do
    
      task :all  => [:areas, "db:populate:places", "db:populate:addresses", :tags]
    
      desc "Init areas database"
      task :areas do
        # create default areas

        @us = Country.create(:name => "United States", :ab => "US")
        Area.create(:extent => @us)
        
        [{:city => "Chicago", :state => "Illinois", :ab => "IL"},
         {:city => "New York", :state => "New York", :ab => "NY"},
         {:city => "San Francisco", :state =>  "California", :ab => "CA"}].each do |hash|
          @state  = State.create(:name => hash[:state], :ab => hash[:ab], :country => @us)
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
          
          # pick a random place
          address.places.push(Place.find(rand(Place.count) + 1))
          address.save
          
          addresses += 1
        end
        puts "#{Time.now}: tagged all #{addresses} addresses with a city and state areas, and a place"

        # add tags to each place
        places  = 0
        tags    = ['coffee', 'beer', 'soccer']
        Place.all.each do |place|
          # pick a random address
          place.addresses.push(Address.find(rand(Address.count) + 1))
          
          # pick a random tag and add it to the address
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