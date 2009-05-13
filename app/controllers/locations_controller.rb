class LocationsController < ApplicationController

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
        format.html { redirect_to(place_path(@location)) }
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