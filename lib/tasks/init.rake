require 'fastercsv'
require 'ar-extensions'

namespace :init do

  desc "Initialize default values."
  task :all => [:countries, :states, :cities, :communities, :state_zips, :tag_groups, :admin_users, "rp:init"]

  desc "Initialize admin users"
  task :admin_users do 
    # Create admin users
    puts "adding admin user: admin@killianmurphy.com, password: peanut"
    a = User.create(:name => "Admin Killian", :email => "admin@killianmurphy.com", :phone => "6504502628",
                    :password => "peanut", :password_confirmation => "peanut")
    a.register!
    a.activate!
    a.grant_role('admin')
    a.mobile_carrier = MobileCarrier.find_by_name("AT&T/Cingular")
    a.save

    puts "adding admin user: sanjay@jarna.com, password: peanut"
    a = User.create(:name => "Admin Sanjay", :email => "sanjay@jarna.com", :phone => "6503876818",
                    :password => "peanut", :password_confirmation => "peanut")
    a.register!
    a.activate!
    a.grant_role('admin')
    a.mobile_carrier = MobileCarrier.find_by_name("Verizon Wireless")
    a.save
    
    puts "#{Time.now}: completed"
  end
  
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
    file    = "#{RAILS_ROOT}/data/states.txt"
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
  
  desc "Initialize basic set of cities"
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
  
  "Initialize communities, which are treated as cities"
  task :communities do
    # import communities as cities
    Community.import

    puts "#{Time.now}: initialized communities"
  end

  desc "Geocode all locations"
  task :geocode_latlngs do
    puts "#{Time.now}: geocoding all locations"
    
    Location.find_in_batches(:batch_size => 1000) do |locations|
      locations.each do |location|
        location.geocode_latlng
      end
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

    puts "#{Time.now}: importing tag groups ... parsing file #{file}" 
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
    
    puts "#{Time.now}: importing state zips ... parsing file #{file}" 
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

end # init
