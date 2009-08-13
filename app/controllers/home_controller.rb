class HomeController < ApplicationController
  
  def index
    @country = Country.default

    self.class.benchmark("Benchmarking featured/closest city") do
      # find a city to highlight
      @featured_city  = find_closest_city_using_ip || find_default_city
      @featured_state = @featured_city.state
    end

    # find featured city objects
    featured_limit = 5

    self.class.benchmark("Benchmarking #{@featured_city.name} featured places") do
      @featured_places = Rails.cache.fetch("#{@featured_city.name.parameterize}:featured:places", :expires_in => CacheExpire.locations) do
        ThinkingSphinx::Search.search(:with => Search.attributes(@featured_city), :classes => [Location],
                                      :include => [:company, :state, :city, :zip, :primary_phone_number], 
                                      :page => 1, :per_page => featured_limit, :order => :popularity, :sort_mode => :desc)
      end
      # @featured_places.map { |o| o.lat = nil; o.lng = nil; o.freeze }
      @featured_places_title = "#{@featured_city.name} Places"
    end

    self.class.benchmark("Benchmarking #{@featured_city.name} featured events") do
      @featured_events = Rails.cache.fetch("#{@featured_city.name.parameterize}:featured:events", :expires_in => CacheExpire.locations) do
        ThinkingSphinx::Search.search(:with => Search.attributes(@featured_city), :classes => [Appointment], :include => {:location => :company}, 
                                      :page => 1, :per_page => featured_limit, :order => :start_at, :sort_mode => :asc)
      end
      @featured_events_title  = "#{@featured_city.name} Events"
      @featured_events_date   = "Today is #{Time.now.to_s(:appt_day_short)}"
      @featured_events_more   = "More #{@featured_city.name} Events"

      # use places if there are no events
      if @featured_events.blank?
        @featured_events = ThinkingSphinx::Search.search(:with => Search.attributes(@featured_city), :classes => [Location], 
                                                         :page => 2, :per_page => featured_limit, :order => :popularity, :sort_mode => :desc)
        @featured_events_title  = "#{@featured_city.name} Places"
        @featured_events_date   = nil
        @featured_events_more   = nil
      end
    end

    # find popular cities based on city density
    self.class.benchmark("Benchmarking popular cities using database") do
      city_limit      = 10
      city_density    = City.popular_density
      @cities         = Rails.cache.fetch("popular_cities:#{city_limit}:#{city_density}", :expires_in => CacheExpire.localities) do
        City.min_density(city_density).order_by_density.all(:limit => city_limit, :include => [:state])
      end
    end

    # initialize neighborhood cities from popular cities
    @hood_limit       = 10
    @hood_cities      = @cities.slice(0, @hood_limit)
    @hood_city_limit  = 25
    
    # self.class.benchmark("Benchmarking popular city neighborhoods using database") do
    #   hood_limit      = 25
    #   # build hash mapping cities to their neighborhoods ordered by density
    #   @neighborhoods  = Rails.cache.fetch("popular_neighborhoods:#{hood_limit}", :expires_in => CacheExpire.localities) do
    #     @cities.inject(ActiveSupport::OrderedHash.new) do |hash, city|
    #       hash[city]  = city.neighborhoods.with_locations.order_by_density.all(:limit => hood_limit)
    #       hash
    #     end
    #   end
    # end

    # track event
    track_home_ga_event(params[:controller], "Index")

    respond_to do |format|
      format.html
    end
  end

  # Handle all unauthorized access redirects
  def unauthorized
    respond_to do |format|
      format.html
    end
  end

  protected

  def find_default_city
    city = Rails.cache.fetch("default_city", :expires_in => 24.hours) do
      state = State.find_by_name("Illinois")
      city  = state.cities.find_by_name("Chicago")
    end
  end
  
  def find_random_city
    # find a randomly selected featured city
    city = City.min_density(City.popular_density).order_by_density.all(:limit => 1, :include => :state, :order => 'rand()').first
  end

  def find_closest_city_using_ip
    begin
      # map request ip to lat/lng coordinates
      ip    =  request.ip # '173.45.229.171'
      # db    = GeoIPCity::Database.new('GeoLiteCity.dat', :filesystem)
      # hash  = db.look_up(ip)
      
      # find closest city, with constraint that city must have a minimum density
      # city  = City.find_closest(:origin => [hash[:latitude], hash[:longitude]], :conditions => ["locations_count > ?", City.popular_density])
      city  = City.find_closest(:origin => ip, :conditions => ["locations_count > ?", City.popular_density])
      # raise Exception, "skipping"
    rescue Exception => e
      logger.debug("xxx find closest city exception: #{e.message}")
      city  = nil
    end

    city
  end

end