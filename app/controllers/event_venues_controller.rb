class EventVenuesController < ApplicationController
  before_filter   :init_localities, :only => [:country, :city]

  privilege_required  'manage site', :on => :current_user

  def country
    # @country initialized in before filter
    
    # find cities with event venues
    @cities     = EventVenue.count(:group => "city").sort_by { |k, v| -v }.map do |city, count|
      # map city name to object, remove empty cities
      city = City.find_by_name(city, :include => :state)
      city ? [city, city.state, count] : nil
    end.compact
    
    # group by state
    @states     = @cities.group_by do |city, state, count|
      state
    end

    @unmapped_count   = EventVenue.unmapped.count
    @mapped_count     = EventVenue.mapped.count
    
    # map unmapped venues to city, state values
    @unmapped_hash    = EventVenue.unmapped.inject(Hash.new(0)) do |hash, venue|
      city_state        = "#{venue.city}:#{venue.state}"
      hash[city_state]  = hash[city_state] + 1
      hash
    end
    
    logger.debug("*** #{@unmapped_hash}")
    
    @title      = "#{@country.name} Event Venues Directory"
    @h1         = @title
  end
  
  def city
    # @country, @state, @city all initialized in before filter

    @filter   = params[:filter] ? params[:filter] : 'all'
    @filters  = ['all', 'mapped', 'unmapped'] - Array(@filter)
    
    @venues   = EventVenue.city(@city).order_by_city_name.send(@filter).paginate(:page => params[:page], :per_page => 20)
    
    logger.debug("*** found #{@venues.size} venues")

    @title  = "#{@city.name} Event Venues Directory - #{@filter.titleize} Venues"
    @h1     = @title
  end
  
  # /veneus/1/add
  def add
    @venue      = EventVenue.find(params[:id])
    
    # map venue city to a city object
    @city       = City.find_by_name!(@venue.city)
    @zip        = Zip.find_by_name(@venue.zip)
    @state      = @city.state
    @country    = @state.country
    
    # build locality collections for location form
    @countries  = Array(@country).collect { |o| [o.name, o.id] }
    @states     = Array(@state).collect { |o| [o.name, o.id] }
    @cities     = Array(@city).collect { |o| [o.name, o.id] }
    @zips       = Array(@zip).compact.collect { |o| [o.name, o.id] }
    
    # initialize location
    @location   = Location.new(:name => @venue.name, :street_address => @venue.address, :city => @city, :state => @state, 
                               :zip => @zip, :country => @country)


    @title    = "Add Event Venue as a Place"
    @h1       = @title
  end
  
end