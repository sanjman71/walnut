class LocationsController < ApplicationController

  # GET /locations/1
  def show
    @location = Location.find(params[:id], :include => [:places])
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
    @search           = Search.parse([@country, @state, @city])
    @nearby_limit     = 7
    
    if @location.mappable?
      @nearby_locations = Location.search(:geo => [Math.degrees_to_radians(@location.lat).to_f, Math.degrees_to_radians(@location.lng).to_f],
                                          :conditions => @search.field(:locality_hash),
                                          :without_ids => @location.id,
                                          :order => "@geodist ASC", 
                                          :limit => @nearby_limit,
                                          :include => [:places])

      @nearby_event_venues = Location.search(:geo => [Math.degrees_to_radians(@location.lat).to_f, Math.degrees_to_radians(@location.lng).to_f],
                                             :conditions => @search.field(:locality_hash).update(:event_venue => 1..10),
                                             :without_ids => @location.id,
                                             :order => "@geodist ASC", 
                                             :limit => @nearby_limit,
                                             :include => [:places])
    end
    
    # initialize title, h1 tags
    @title    = @place.name
    @h1       = @title
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