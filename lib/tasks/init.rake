namespace :db do  
  namespace :init do
    
    task :all  => [:areas, "db:populate:addresses", :tags]
    
    desc "Init areas database"
    task :areas do
      # create default areas

      [{:city => "Chicago", :state => "Illinois", :ab => "IL"},
       {:city => "New York", :state => "New York", :ab => "NY"},
       {:city => "San Francisco", :state =>  "California", :ab => "CA"}].each do |hash|
        @state  = State.create(:name => hash[:state], :ab => hash[:ab], :country => "US")
        @city   = City.create(:name => hash[:city], :state => @state)
        Area.create(:extent => @state)
        Area.create(:extent => @city)
      end
      
      puts "#{Time.now}: initialized #{Area.count} areas"
    end
    
    desc "Init tags database by tagging each location with a city and state area"
    task :tags do 
      places = 0
      Address.all.each do |address|
        # pick a random city
        city  = City.find(rand(City.count) + 1)
        state = city.state
        address.areas.push(city.areas.first)
        address.areas.push(state.areas.first)
        address.save
        places += 1
      end
      
      puts "#{Time.now}: tagged every place (#{places}) with a city and state area"
    end
    
  end
end