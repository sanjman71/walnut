require 'fastercsv'
require 'ar-extensions'

namespace :init do

  desc "Initialize default values."
  task :all => [:countries, :states, :cities, :communities, :townships, :zips, :tag_groups, :admin_users, "rp:init", "events:init"]

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

    puts "#{Time.now}: importing states ... parsing file #{file}" 
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
    count = City.import
    puts "#{Time.now}: initialized #{count} cities"
  end
  
  desc "Initialize communities, which are imported as cities"
  task :communities do
    # import communities as cities
    count = Community.import
    puts "#{Time.now}: initialized #{count} communities"
  end

  desc "Initialize townships, which are imported as cities"
  task :townships do
    # import townships as cities
    count = Township.import
    puts "#{Time.now}: initialized #{count} townships"
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
  
  desc "Initialize zips"
  task :zips do
    klass   = Zip
    columns = [:name, :state_id, :lat, :lng]
    file    = "#{RAILS_ROOT}/data/zips.txt"
    values  = []
    options = { :validate => false }
    
    puts "#{Time.now}: importing state zips ... parsing file #{file}" 
    FasterCSV.foreach(file, :row_sep => "\n", :col_sep => '|') do |row|
      name, state_code, lat, lng = row

      # validate state
      state = State.find_by_code(state_code)
      next if state.blank?
      
      # check if zip already exists
      next if state.zips.find_by_name(name)

      value = [name, state.id, lat, lng]
      values << value
    end

    # import data
    puts "#{Time.now}: importing data, starting with #{klass.count} objects"
    klass.import columns, values, options if !values.blank?
    puts "#{Time.now}: completed, ended with #{klass.count} objects" 
  end

end # init
