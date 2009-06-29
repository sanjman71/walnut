class LocationsController < ApplicationController

  # GET /locations/1-hall-of-justice
  def show
    @location = Location.find(params[:id], :include => [:places, :country, :state, :city, :zip, :neighborhoods])
    @place    = @location.place unless @location.blank?

    if @location.blank? or @place.blank?
      redirect_to(:controller => 'places', :action => 'error', :locality => 'location') and return
    end

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
      # self.class.benchmark("Benchmarking upcoming events at event venue") do
        @event_limit      = LocationNeighbor.default_limit
        @location_events  = @location.events.future.all(:order => 'start_at asc')
        logger.debug("*** location events: #{@location_events.size}")
      # end
    end

    if @location.mappable?
      self.class.benchmark("Benchmarking nearby locations and event venues") do
        @nearby_locations, @nearby_event_venues = Rails.cache.fetch("#{@location.cache_key}:nearby", :expires_in => CacheExpire.locations) do

          # partition neighbors into regular and event venue locations
          @nearby_limit = LocationNeighbor.default_limit
          @nearby_locations, @nearby_event_venues = LocationNeighbor.partition_neighbors(@location, :limit => @nearby_limit)

          if @nearby_locations.blank? and @nearby_event_venues.blank?
            # initialize neighbors and try again
            LocationNeighbor.set_neighbors(@location, :limit => @nearby_limit, :geodist => 0.0..LocationNeighbor.default_radius_meters)
            @nearby_locations, @nearby_event_venues = LocationNeighbor.partition_neighbors(@location, :limit => @nearby_limit)
          end

          [@nearby_locations, @nearby_event_venues]
        end
      end
    end
    
    # initialize title, h1 tags
    @title    = build_place_title(@place, @location, :city => @city, :state => @state, :zip => @zip)
    @h1       = @place.name
  end

  # GET /locations/:city/random
  def random
    # build collection of location ids from the specified city
    @city = City.find_by_name(params[:city].titleize)

    raise ArgumentError, "invalid city" if @city.blank?

    self.class.benchmark("Benchmarking find #{@city.name} location ids") do
      @location_ids = Rails.cache.fetch("#{@city.name.parameterize}:location_ids") do
        Location.with_city(@city).all(:select => 'id').collect(&:id)
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