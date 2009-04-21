require 'fastercsv'
require 'ar-extensions'

namespace :init do

  desc "Initialize default values."
  # task :all => [:countries, :states, :locations, "db:populate:places", :tags, :chains, :city_zips, :geocode_latlngs]
  task :all => [:countries, :states, :cities, :state_zips, :tag_groups, "rp:init",
                "eventful:import_categories", "eventful:create_cities", "eventful:mark_cities"
               ]

  desc "Initialize countries."
  task :countries do
    @us = Country.create(:name => "United States", :code => "US")
    puts "#{Time.now}: initialized countries"
  end

  desc "Initialize states."
  task :states do
    @us     = Country.find_by_code("US")
    
    klass   = State
    columns = [:id, :name, :code, :country_id, :lat, :lng]
    file    = "#{RAILS_ROOT}/states.txt"
    values  = []
    options = { :validate => false }

    puts "#{Time.now}: parsing file #{file}" 
    FasterCSV.foreach(file, :row_sep => "\n", :col_sep => ',') do |row|
      id, name, code, lat, lng = row
      value = [id, name, code, @us.id, lat, lng]
      values << value
    end

    # import data
    puts "#{Time.now}: importing data, starting with #{klass.count} objects"
    klass.import columns, values, options 
    puts "#{Time.now}: completed, ended with #{klass.count} objects"
    
    puts "#{Time.now}: initialized states"
  end
  
  desc "Initialize first set of cities"
  task :cities do

    ["IL"].each do |code|
      @state = State.find_by_code(code)
      ['Chicago'].each do |city_name|
        Locality.validate(@state, 'city', city_name)
      end
    end

    ["NY"].each do |code|
      @state = State.find_by_code(code)
      ['New York'].each do |city_name|
        Locality.validate(@state, 'city', city_name)
      end
    end

    ["NC"].each do |code|
      @state = State.find_by_code(code)
      ['Charlotte'].each do |city_name|
        Locality.validate(@state, 'city', city_name)
      end
    end

    ["PA"].each do |code|
      @state = State.find_by_code(code)
      ['Philadelphia'].each do |city_name|
        Locality.validate(@state, 'city', city_name)
      end
    end
    
    ["CO"].each do |code|
      @state = State.find_by_code(code)
      ['Denver'].each do |city_name|
        Locality.validate(@state, 'city', city_name)
      end
    end

    ["AZ"].each do |code|
      @state = State.find_by_code(code)
      ['Phoenix'].each do |city_name|
        Locality.validate(@state, 'city', city_name)
      end
    end
    
    puts "#{Time.now}: initialized cities"
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
  
  desc "Geocode all locations"
  task :geocode_latlngs do
    Location.all.each do |location|
      location.geocode_latlng
    end
    
    puts "#{Time.now}: geocoded #{Location.count} locations"
  end
  
  desc "Initialize default tag groups"
  task :tag_groups do
    klass   = TagGroup
    columns = [:id, :name, :tags, :applied_at]
    file    = "#{RAILS_ROOT}/data/tag_groups.txt"
    values  = []
    options = { :validate => false }

    puts "#{Time.now}: parsing file #{file}" 
    FasterCSV.foreach(file, :row_sep => "\n", :col_sep => '|') do |row|
      id, name, tags = row
      value = [id, name, tags, Time.now]
      values << value
    end

    # import data
    puts "#{Time.now}: importing data, starting with #{klass.count} objects"
    klass.import columns, values, options 
    puts "#{Time.now}: completed, ended with #{klass.count} objects" 
  end
  
  desc "Initialize state zips"
  task :state_zips do
    klass   = Zip
    columns = [:id, :name, :state_id, :lat, :lng]
    file    = "#{RAILS_ROOT}/data/state_zips.txt"
    values  = []
    options = { :validate => false }
    
    puts "#{Time.now}: parsing file #{file}" 
    FasterCSV.foreach(file, :row_sep => "\n", :col_sep => '|') do |row|
      id, name, state_id, lat, lng = row
      value = [id, name, state_id, lat, lng]
      values << value
    end

    # import data
    puts "#{Time.now}: importing data, starting with #{klass.count} objects"
    klass.import columns, values, options 
    puts "#{Time.now}: completed, ended with #{klass.count} objects" 
  end
  
  desc "Import neighborhood info using the urban mapping api"
  task :urban_neighborhoods do
    limit       = ENV["LIMIT"].to_i if ENV["LIMIT"]
    city        = ENV["CITY"].titleize if ENV["CITY"]
    state_code  = ENV["STATE"].upcase if ENV["STATE"]
    added       = 0

    # build conditions
    conditions  = {:neighborhoods_count => 0}
    
    if city and state_code
      state = State.find_by_code(state_code)
      city  = state.cities.find_by_name(city)
      
      if state.blank? or city.blank?
        puts "*** invalid city, state"
        exit
      end
      
      conditions.update(:city_id => city.id)
      conditions.update(:state_id => state.id)
    end
    
    # find locations with no neighborhoods, matching conditions
    Location.all(:conditions => conditions).each do |location|
      neighborhoods = UrbanMapping::Neighborhood.find_by_latlng(location.lat, location.lng)
      
      # add neighborhoods
      neighborhoods.each do |neighborhood|
        next if location.neighborhoods.include?(neighborhood)
        location.neighborhoods.push(neighborhood)
        added += 1
      end
      
      if limit and added >= limit
        puts "#{Time.now}: *** reached limit #{limit}"
        break
      end
      
      # throttle calls to urban mapping
      Kernel.sleep(1)
    end
    
    puts "#{Time.now}: imported #{added} neighborhoods from urban mapping"
  end
  
end # init
