require 'fastercsv'
require 'ar-extensions'

namespace :init do

  desc "Initialize default values."
  task :all => [:countries, :states, :cities, :communities, :townships, :zips, :timezones, :tag_groups, "rp:init", "events:init"]

  # desc "Initialize admin users"
  # task :admin_users do 
  #   # Create admin users
  #   puts "adding admin user: admin@killianmurphy.com, password: peanut"
  #   a = User.create(:name => "Admin Killian", :email => "admin@killianmurphy.com", :phone => "6504502628",
  #                   :password => "peanut", :password_confirmation => "peanut")
  #   a.register!
  #   a.activate!
  #   a.grant_role('admin')
  #   a.mobile_carrier = MobileCarrier.find_by_name("AT&T/Cingular")
  #   a.save
  # 
  #   puts "adding admin user: sanjay@jarna.com, password: peanut"
  #   a = User.create(:name => "Admin Sanjay", :email => "sanjay@jarna.com", :phone => "6503876818",
  #                   :password => "peanut", :password_confirmation => "peanut")
  #   a.register!
  #   a.activate!
  #   a.grant_role('admin')
  #   a.mobile_carrier = MobileCarrier.find_by_name("Verizon Wireless")
  #   a.save
  #   
  #   puts "#{Time.now}: completed"
  # end
  
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
  
  desc "Initialize time zones"
  task :timezones do
    klass   = Timezone
    columns = [:name, :utc_offset, :utc_dst_offset]
    file    = "#{RAILS_ROOT}/data/timezones.txt"
    values  = []
    options = { :validate => false }

    puts "#{Time.now}: importing timezones ... parsing file #{file}" 
    # use File.open here instead of FasterCSV because FasterCSV doesn't like the file format
    File.open(file).each do |row|
      name, utc_offset, utc_dst_offset = row.split(" ")
      
      # skip if object already exists
      next if Timezone.find_by_name(name)

      # convert offset in hours to seconds
      utc_offset      = utc_offset.to_f * 3600
      utc_dst_offset  = utc_dst_offset.to_f * 3600
      
      value = [name, utc_offset, utc_dst_offset]
      values << value
    end

    # import data
    puts "#{Time.now}: importing data, starting with #{klass.count} objects"
    klass.import columns, values, options if values.any?
    puts "#{Time.now}: completed, ended with #{klass.count} objects"
    
    puts "#{Time.now}: mapping timezones to rails timezones"
    
    # map unmapped timezones to rails timezones
    Timezone.find(:all, :conditions => ["rails_time_zone_name IS NULL"]).each do |timezone|
      # find all matching rails timezones
      rails_time_zones = ActiveSupport::TimeZone.all.find_all { |tz| tz.utc_offset == timezone.utc_offset }
      
      if rails_time_zones.empty? 
        # puts "*** timezone: #{timezone.name} could not be mapped to a rails time zone"
        next
      end
      
      # check 'America' time zones that may be mapped to more than 1 rails time zone
      if timezone.name.match(/America\//) and rails_time_zones.size > 1
        # map to rails time zone in us or canada
        us_cities = ["Anchorage", "Boise", "Chicago", "Dawson", "Dawson Creek", "Denver", "Detroit", "Indiana", "Kentucky", "Juneau", "Menominee",
                     "Los Angeles", "New York", "North Dakota", "Phoenix", "Shiprock"]
        
        ca_cities = ["Edmonton", "Montreal", "Toronto", "Vancouver", "Winnipeg"]
        
        city_name = timezone.name.split("/")[1].titleize
        
        if us_cities.include?(city_name) || ca_cities.include?(city_name)
          # map us/canada city to a us/canada rails timezone
          us_rails_time_zones = rails_time_zones.find_all { |tz| tz.name.match(/US/) }

          if us_rails_time_zones.size == 1
            us_rails_time_zone = us_rails_time_zones.first
            timezone.rails_time_zone_name = us_rails_time_zone.name
            timezone.save
          end
        end
      end

      # TODO: we need to uniquely identify a timezone from this list
      if rails_time_zones.size > 1
        # puts "xxx timezone: #{timezone.name} - found #{rails_time_zones.size} mappings to #{rails_time_zones.collect(&:name).join(" | ")}"
        next
      end

      # found a unique mapping so add the rails time zone
      timezone.rails_time_zone_name = rails_time_zones.first.name
      timezone.save
    end
    
    puts "#{Time.now}: completed"
  end
  
  desc "Initialize default tag groups"
  task :tag_groups do
    klass   = TagGroup
    columns = [:name, :tags, :applied_at]
    file    = "#{RAILS_ROOT}/data/tag_groups.txt"
    values  = []
    options = { :validate => false }

    puts "#{Time.now}: importing tag groups ... parsing file #{file}" 
    FasterCSV.foreach(file, :row_sep => "\n", :col_sep => '|') do |row|
      id, name, tags = row
      
      # skip if tag group already exists
      next if TagGroup.find_by_name(name)
      
      value = [name, tags, Time.now]
      values << value
    end

    # import data
    puts "#{Time.now}: importing data, starting with #{klass.count} objects"
    klass.import columns, values, options if values.any?
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
