class PlacesController < ApplicationController
  before_filter   :init_areas, :only => [:country, :state, :city, :neighborhood, :zip, :index]
  layout "home"
  
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
    @tags   = Place.tag_counts.sort_by(&:name)
    @title  = "#{@city.name}, #{@state.name} Yellow Pages"
  end

  def neighborhood
    # @country, @state, @city, @neighborhood all initialized in before filter
    @tags   = Place.tag_counts.sort_by(&:name)
    @title  = "#{@neighborhood.name}, #{@city.name}, #{@state.name} Yellow Pages"
  end
  
  def zip
    # @country, @state, @zip and @cities all initialized in before filter
    @tags   = Place.tag_counts.sort_by(&:name)
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
    
    # find city neighborhoods if its a city search
    @neighborhoods  = @city.neighborhoods unless @city.blank?
    
    # find city zips if its a city search
    @zips           = @city.zips unless @city.blank?

    # find nearby cities if its a city search
    @nearby_cities  = City.exclude(@city).within_state(@state).all(:origin => @city) unless @city.blank?
    
    # find zip cities if its a zip search
    @cities         = @zip.cities unless @zip.blank?
    
    # build search title based on city, neighborhood, zip search
    @title          = build_search_title(:what => @what, :city => @city, :neighborhood => @neighborhood, :zip => @zip, :state => @state)
    @h1             = @title
    
    # build search object
    @search         = Search.parse([@country, @state, @city, @neighborhood, @zip], @what)
    @tags           = @search.place_tags
    
    # use 'what' param to search name and place_tags fields
    # use 'where' param as locality_tags field filter
    @locations      = Location.search(@search.multiple_fields(:name, :place_tags), 
                                      :conditions => {:locality_tags => @search.field(:locality_tags)}, 
                                      :include => [:locatable]).paginate(:page => params[:page])
  end
  
  def show
    @location = Location.find(params[:id], :include => [:locatable, :locality_tags])
    @place    = @location.locatable unless @location.blank?

    if @location.blank? or @place.blank?
      redirect_to(:controller => 'places', :action => 'error', :area => 'location') and return
    end

    # initialize localities
    @country          = @location.country
    @state            = @location.state
    @city             = @location.city
    @zip              = @location.zip
    @neighborhoods    = @location.neighborhoods
    
    # find nearby locations
    @nearby_locations = []
    
    @title    = "#{@place.name}"
    @h1       = @title
  end
  
  def error
    @error_text = "We are sorry, but we couldn't find the #{params[:area]} you were looking for."
  end
  
  protected
  
  def build_search_title(options={})
    what = options[:what] || ''
    
    if options[:state] and options[:city] and options[:neighborhood]
      where = "#{options[:neighborhood].name}, #{options[:city].name}, #{options[:state].name}"
    elsif options[:state] and options[:city]
      where = "#{options[:city].name}, #{options[:state].name}"
    elsif options[:state] and options[:zip]
      where = "#{options[:state].name}, #{options[:zip].name}"
    else
      raise Exception, "invalid search"
    end
    
    "#{what.titleize} near #{where}"
  end
  
  def init_areas
    # country is required for all actions
    @country  = Country.find_by_code(params[:country].to_s.upcase)
    
    if @country.blank?
      redirect_to(:controller => 'places', :action => 'error', :area => 'country') and return
    end
    
    case params[:action]
    when 'country'
      # find all states
      @states = @country.states
      return true
    else
      # find the specified state for all other cases
      @state  = State.find_by_code(params[:state].to_s.upcase)
    end

    if @state.blank?
      redirect_to(:controller => 'places', :action => 'error', :area => 'state') and return
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
        redirect_to(:controller => 'places', :action => 'error', :area => 'city') and return
      end
    when 'neighborhood'
      # find city and neighborhood
      @city           = @state.cities.find_by_name(params[:city].to_s.titleize)
      @neighborhood   = @city.neighborhoods.find_by_name(params[:neighborhood].to_s.titleize) unless @city.blank?

      if @city.blank? or @neighborhood.blank?
        redirect_to(:controller => 'places', :action => 'error', :area => 'city') and return if @city.blank?
        redirect_to(:controller => 'places', :action => 'error', :area => 'neighborhood') and return if @neighborhood.blank?
      end
    when 'zip'
      # find zip and all its cities
      @zip      = @state.zips.find_by_name(params[:zip].to_s)
      @cities   = @zip.cities unless @zip.blank?

      if @zip.blank?
        redirect_to(:controller => 'places', :action => 'error', :area => 'zip') and return
      end
    end
    
    return true
  end
  
end
