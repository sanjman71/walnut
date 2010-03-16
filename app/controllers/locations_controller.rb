class LocationsController < ApplicationController
  # use the acts_as_friendly_param plugin filter to handle showing a unique friendly url for the location
  around_filter ActionController::FriendlyFilter.new

  before_filter :force_full_site, :only => [:show]

  # GET /locations/1-hall-of-justice
  def show
    @location = Location.find(params[:id], :include => [:companies, :country, :state, :city, :zip, :neighborhoods])
    @company  = @location.company unless @location.blank?

    if @location.blank? or @company.blank?
      redirect_to(:controller => 'search', :action => 'error', :locality => 'location') and return
    end

    # check params, default to 0
    @neighbors        = params[:neighbors] ? params[:neighbors].to_i : 0

    # initialize localities
    @country          = @location.country
    @state            = @location.state
    @city             = @location.city
    @zip              = @location.zip
    @neighborhoods    = @location.neighborhoods

    # initialize the weather
    @weather          = init_weather

    if @location.events_count > 0
      # find upcoming events at this event venue
      self.class.benchmark("*** Benchmarking upcoming events at event venue", APP_LOGGER_LEVEL, false) do
        @event_limit      = LocationNeighbor.default_limit
        @location_events  = @location.appointments.public.future.all(:order => 'start_at asc')
      end
    end

    if @location.mappable?
      self.class.benchmark("*** Benchmarking nearby locations and event venues", APP_LOGGER_LEVEL, false) do
        @nearby_locations, @nearby_event_venues = Rails.cache.fetch("#{@location.cache_key}:nearby", :expires_in => CacheExpire.locations) do

          # partition neighbors into regular and event venue locations
          @nearby_limit = LocationNeighbor.default_limit
          @nearby_locations, @nearby_event_venues = LocationNeighbor.partition_neighbors(@location, :limit => @nearby_limit)

          if @nearby_locations.blank? and @nearby_event_venues.blank? and (@neighbors == 1)
            # initialize neighbors and try again
            LocationNeighbor.set_neighbors(@location, :limit => @nearby_limit, :geodist => 0.0..LocationNeighbor.default_radius_meters)
            @nearby_locations, @nearby_event_venues = LocationNeighbor.partition_neighbors(@location, :limit => @nearby_limit)
          end

          [@nearby_locations, @nearby_event_venues]
        end
      end
    end

    # initialize title, h1 tags
    @title    = build_place_title(@company, @location, :city => @city, :state => @state, :zip => @zip)
    @h1       = @company.name
  end

  # GET /locations/:city/random
  def random
    # build collection of location ids from the specified city
    @city = City.find_by_name(params[:city].titleize)

    raise ArgumentError, "invalid city" if @city.blank?

    self.class.benchmark("Benchmarking find #{@city.name} location ids") do
      @location_ids = Rails.cache.fetch("#{@city.name.to_url_param}:location_ids") do
        Location.with_city(@city).all(:select => 'id', :limit => 5000).collect(&:id)
      end
    end

    # pick a random location
    @location = Location.find_by_id(@location_ids[rand(@location_ids.size)])

    # set id, call show method and render show action
    params[:id] = @location.id
    show

    respond_to do |format|
      format.html { render(:action => 'show') }
    end
  end

  # POST /locations
  def create
    begin
      @location = Location.new(params[:location])
    rescue ActiveRecord::AssociationTypeMismatch => e
      # check params
      if zip_s = params[:location].delete(:zip)
        # convert zip string to an object
        zip = Zip.find_by_name(zip_s.to_s.strip)
        if zip.blank?
          flash[:error] = "Invalid zip"
          redirect_to(request.referer) and return
        end
        # try again with a valid zip
        @location = Location.new(params[:location])
        @location.zip = zip
      else
        raise e
      end
    end
    
    Location.transaction do
      # create place
      @place = Place.create(:name => @location.name)
      @location.save

      raise ActiveRecord::Rollback if !@place.valid? or !@location.valid?
      
      # geocode location coordinates
      @location.geocode_latlng
      
      # add place to location mapping
      @place.locations.push(@location)
    end

    if @place.valid? and @location.valid?
      # check event venue
      if params[:event_venue_id] and @venue = EventVenue.find_by_id(params[:event_venue_id])
        logger.debug("*** mapping new place to event venue #{@venue.name}")
        @venue.location = @location
        @venue.save
      end
    end
    
    if @place.valid? and @location.valid?
      flash[:notice] = 'Location was successfully created.'
      respond_to do |format|
        format.html { redirect_to(location_path(@location)) }
      end
    else
      flash[:error] = 'Error creating location.'
      respond_to do |format|
        format.html { redirect_to(request.referer) }
      end
    end
  end

  # GET /locations/1/edit
  def edit
    @location = Location.find(params[:id], :include => [:companies, :country, :state, :city, :zip, :neighborhoods])
    @company  = @location.company unless @location.blank?

    if @location.blank? or @company.blank?
      redirect_to(:controller => 'search', :action => 'error', :locality => 'location') and return
    end

    @countries  = [@location.country]
    @states     = [@location.state]
    @cities     = (@location.state.andand.cities || []).sort_by{|o| o.name}
    @zips       = (@location.state.andand.zips || []).sort_by{|o| o.name}
  
    respond_to do |format|
      format.html
    end
  end

  # PUT /locations/1
  def update
    @location = Location.find(params[:id], :include => [:companies, :country, :state, :city, :zip, :neighborhoods])
    @company  = @location.company unless @location.blank?

    if @location.blank? or @company.blank?
      redirect_to(:controller => 'search', :action => 'error', :locality => 'location') and return
    end

    @locality_changes = 0
    params[:location].keys.each do |key|
      next unless [:country_id, :state_id, :city_id, :zip_id, :neighborhood_id].include?(key.to_sym)
      begin
        # get class object
        klass_name  = key.to_s.split("_").first.titleize
        klass       = Module.const_get(klass_name)
      rescue
        next
      end

      begin
        locality = klass.find_by_id(params[:location][key])
        method   = klass_name.downcase + "="
        @location.send(method, locality)
        @locality_changes += 1
        # delete it from params since its already updated
        params[:location].delete(key)
      rescue
        next
      end
    end

    @success = @location.update_attributes(params[:location])

    if @success
      flash[:notice] = "Location updated"

      if @locality_changes > 0
        @location.geocode_latlng(:force => true)
        flash[:notice] = "Location and map updated"
      end
    else
      flash[:error] = "Location update failed"
    end

    # if !@success
    #   puts "*** errors: #{@success.errors.full_messages}"
    # end

    redirect_to(location_path(@location))
  end


  # POST /locations/1/recommend
  def recommend
    @location = Location.find(params[:id])
    
    # increment location recommendations count
    Location.increment_counter(:recommendations_count, @location.id)
    @location.reload
    
    # cache recommendation as part of the session
    cache_recommendation(@location)

    respond_to do |format|
      format.js
    end
  end

end