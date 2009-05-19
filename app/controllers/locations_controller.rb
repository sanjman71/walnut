class LocationsController < ApplicationController

  # GET /locations/1
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
    
    # find nearby locations, within the same city, exclude this location, and sort by distance
    @hash             = Search.query("events:1")
    @attributes       = Search.attributes(@country, @state, @city)
    @nearby_limit     = 7
    
    if @location.mappable?
      self.class.benchmark("Benchmarking nearby locations and event venues") do
        @nearby_locations = Rails.cache.fetch("#{@location.cache_key}:nearby:locations", :expires_in => CacheExpire.locations) do
          Location.search(:geo => [Math.degrees_to_radians(@location.lat).to_f, Math.degrees_to_radians(@location.lng).to_f],
                          :with => @attributes,
                          :without_ids => @location.id,
                          :order => "@geodist ASC", 
                          :limit => @nearby_limit,
                          :include => [:places])
        end

        @nearby_event_venues = Rails.cache.fetch("#{@location.cache_key}:nearby:event_venues", :expires_in => CacheExpire.locations) do
          Location.search(:geo => [Math.degrees_to_radians(@location.lat).to_f, Math.degrees_to_radians(@location.lng).to_f],
                          :with => @attributes.update(@hash[:attributes]),
                          :without_ids => @location.id,
                          :order => "@geodist ASC", 
                          :limit => @nearby_limit,
                          :include => [:places])
        end
      end
    end
    
    # initialize title, h1 tags
    @title    = @place.name
    @h1       = @title
  end

  # GET /locations/random
  def random
    # build collection of location ids from the specified city
    @city = City.find_by_name(params[:city].titleize)

    raise ArgumentError, "invalid city" if @city.blank?

    self.class.benchmark("Benchmarking find #{@city.name} location ids") do
      @location_ids = Rails.cache.fetch("#{@city.name}:location_ids") do
        Location.for_city(@city).all(:select => 'id').collect(&:id)
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
      # create place, use default location name
      @place = Place.create(:name => @location.name)
      @location.name = "Work"
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