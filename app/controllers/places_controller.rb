class PlacesController < ApplicationController
  before_filter   :normalize_page_number, :only => [:index]
  before_filter   :init_areas, :only => [:country, :state, :city, :neighborhood, :zip, :index]
  
  def country
    # @country, @states initialized in before filter
    @title  = "#{@country.name} Yellow Pages"
  end
      
  def state
    # @country, @state, @cities, @zips all initialized in before filter
    @title  = "#{@state.name} Yellow Pages"
  end
  
  def city
    # @country, @state, @city, @zips and @neighborhoods all initialized in before filter
    
    # generate city specific tag counts
    @tags   = @city.places.tag_counts.sort_by(&:name)
    @title  = "#{@city.name}, #{@state.name} Yellow Pages"
  end

  def neighborhood
    # @country, @state, @city, @neighborhood all initialized in before filter

    # generate neighborhood specific tag counts
    @tags   = @neighborhood.locations.places.tag_counts.sort_by(&:name)
    @title  = "#{@neighborhood.name}, #{@city.name}, #{@state.name} Yellow Pages"
  end
  
  def zip
    # @country, @state, @zip and @cities all initialized in before filter

    # generate zip specific tag counts
    @tags   = @zip.places.tag_counts.sort_by(&:name)
    @title  = "#{@state.name} #{@zip.name} Yellow Pages"
  end
  
  def search
    # resolve where parameter
    @locality = Locality.resolve(params[:where].to_s)
    @what     = params[:what].to_s.to_url_param
    
    if @locality.blank?
      redirect_to(:action => 'error', :locality => 'unknown') and return
    end
    
    case @locality.class.to_s
    when 'City'
      @state    = @locality.state
      @country  = @state.country
      redirect_to(:action => 'index', :country => @country, :state => @state, :city => @locality, :what => @what) and return
    when 'Zip'
      @state    = @locality.state
      @country  = @state.country
      redirect_to(:action => 'index', :country => @country, :state => @state, :zip => @locality, :what => @what) and return
    when 'Neighborhood'
      @city     = @locality.city
      @state    = @city.state
      @country  = @state.country
      redirect_to(:action => 'index', :country => @country, :state => @state, :city => @city, :neighborhood => @locality, :what => @what) and return
    when 'State'
      raise Exception, "not allowed to search by state"
    end
    
  end
  
  def index
    @city           = @state.cities.find_by_name(params[:city].to_s.titleize) unless params[:city].blank?
    @zip            = @state.zips.find_by_name(params[:zip].to_s) unless params[:zip].blank?
    @neighborhood   = @city.neighborhoods.find_by_name(params[:neighborhood].to_s.titleize) unless @city.blank? or params[:neighborhood].blank?
    @what           = params[:what].to_s.from_url_param
    @filter         = params[:filter].to_s.from_url_param if params[:filter]
    
    # find city neighborhoods if its a city search
    @neighborhoods  = @city.neighborhoods unless @city.blank?
    
    # find city zips if its a city search
    @zips           = @city.zips.order_by_density.all(:limit => 20) unless @city.blank?

    # find nearby cities if its a city search, where nearby is defined with a mile radius range
    nearby_miles    = 20
    @nearby_cities  = City.exclude(@city).within_state(@state).all(:origin => @city, :within => nearby_miles) unless @city.blank?
    
    # find zip cities if its a zip search
    @cities         = @zip.cities unless @zip.blank?
    
    # build search title based on [what, filter] and city, neighborhood, zip search
    @title          = build_search_title(:what => @what, :filter => @filter, :city => @city, :neighborhood => @neighborhood, :zip => @zip, :state => @state)
    @h1             = @title
    
    # build search object
    @search         = Search.parse([@country, @state, @city, @neighborhood, @zip], @what)
    @tags           = @search.place_tags

    # use 'what' param to search name and place_tags fields
    # use 'where' param as locality_tags field filter - this is the old way
    # use 'where' param as locality_hash conditions filter
    # use filter' to narrow search conditions
    @conditions     = @search.field(:locality_hash)

    case @filter
    when 'recommended'
      @conditions.update(:recommendations => 1..2**30)
    end

    @locations      = Location.search(@search.field(:place_tags), 
                                      :conditions => @conditions, 
                                      :include => [:locatable, :city, :state, :zip],
                                      :order => :search_rank, :sort_mode => :desc,
                                      :page => params[:page], :per_page => 20)
  end
  
  def show
    @location = Location.find(params[:id], :include => [:locatable, :locality_tags])
    @place    = @location.locatable unless @location.blank?

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
                                          :include => [:locatable])
    end
    
    # initialize title, h1 tags
    @title    = @place.name
    @h1       = @title
  end
  
  def error
    @title    = "Search error"
  end
  
  protected
  
  def build_search_title(options={})
    what    = options[:what] || ''
    filter  = options[:filter] || ''

    raise ArgumentError if what.blank? and filter.blank?
    
    if options[:state] and options[:city] and options[:neighborhood]
      where = "#{options[:neighborhood].name}, #{options[:city].name}, #{options[:state].name}"
    elsif options[:state] and options[:city]
      where = "#{options[:city].name}, #{options[:state].name}"
    elsif options[:state] and options[:zip]
      where = "#{options[:state].name}, #{options[:zip].name}"
    else
      raise Exception, "invalid search"
    end

    # use 'what' if its available
    unless what.blank?
      return "#{what.titleize} near #{where}"
    end
    
    # otherwise use 'filter'
    case filter
    when 'recommended'
      return "Recommended places near #{where}"
    end
  end
  
  def init_areas
    # country is required for all actions
    @country  = Country.find_by_code(params[:country].to_s.upcase)
    
    if @country.blank?
      redirect_to(:controller => 'places', :action => 'error', :locality => 'country') and return
    end
    
    case params[:action]
    when 'country'
      # find all states that have locations
      @states = @country.states.with_locations
      return true
    else
      # find the specified state for all other cases
      @state  = State.find_by_code(params[:state].to_s.upcase)
    end

    if @state.blank?
      redirect_to(:controller => 'places', :action => 'error', :locality => 'state') and return
    end
    
    case params[:action]
    when 'state'
      # find all state cities and zips
      @cities = @state.cities
      @zips   = @state.zips
    when 'city'
      # find city, and all its zips and neighborhoods
      @city           = @state.cities.find_by_name(params[:city].to_s.titleize)
      @zips           = @city.zips unless @city.blank?
      @neighborhoods  = @city.neighborhoods unless @city.blank?
      
      if @city.blank?
        redirect_to(:controller => 'places', :action => 'error', :locality => 'city') and return
      end
    when 'neighborhood'
      # find city and neighborhood
      @city           = @state.cities.find_by_name(params[:city].to_s.titleize)
      @neighborhood   = @city.neighborhoods.find_by_name(params[:neighborhood].to_s.titleize) unless @city.blank?

      if @city.blank? or @neighborhood.blank?
        redirect_to(:controller => 'places', :action => 'error', :locality => 'city') and return if @city.blank?
        redirect_to(:controller => 'places', :action => 'error', :locality => 'neighborhood') and return if @neighborhood.blank?
      end
    when 'zip'
      # find zip and all its cities
      @zip      = @state.zips.find_by_name(params[:zip].to_s)
      @cities   = @zip.cities unless @zip.blank?

      if @zip.blank?
        redirect_to(:controller => 'places', :action => 'error', :locality => 'zip') and return
      end
    end
    
    return true
  end
  
  def normalize_page_number
    if params[:page] == '1'
      # redirect to url without page number
      redirect_to(:page => nil) and return
    end
  end
end
