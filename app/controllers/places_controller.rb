class PlacesController < ApplicationController
  before_filter   :normalize_page_number, :only => [:index]
  before_filter   :init_localities, :only => [:country, :state, :city, :neighborhood, :zip, :index]
  
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
    
    # generate tag counts using facets
    options   = {:with => Search.with(@city)}.update(Search.tag_count_options(150))
    @facets   = Location.facets(options)
    @tags     = Search.load_from_facets(@facets, Tag).sort_by { |o| o.name }
    
    @title    = "#{@city.name}, #{@state.name} Yellow Pages"
  end

  def neighborhood
    # @country, @state, @city, @neighborhood all initialized in before filter

    # generate tag counts using facets
    options   = {:with => Search.with(@neighborhood)}.update(Search.tag_count_options(150))
    @facets   = Location.facets(options)
    @tags     = Search.load_from_facets(@facets, Tag).sort_by { |o| o.name }
    
    @title    = "#{@neighborhood.name}, #{@city.name}, #{@state.name} Yellow Pages"
  end
  
  def zip
    # @country, @state, @zip and @cities all initialized in before filter

    # generate tag counts using facets
    options   = {:with => Search.with(@zip)}.update(Search.tag_count_options(150))
    @facets   = Location.facets(options)
    @tags     = Search.load_from_facets(@facets, Tag).sort_by { |o| o.name }
    
    @title    = "#{@state.name} #{@zip.name} Yellow Pages"
  end
    
  def index
    # @country, @state, @city, @zip, @neighborhood all initialized in before filter
    
    @what           = params[:what].to_s.from_url_param
    @filter         = params[:filter].to_s.from_url_param if params[:filter]
    
    # handle special case of 'something' to find a random what
    @what           = Tag.all(:order => 'rand()', :limit => 1).first.name if @what == 'something'

    # find nearby cities if its a city search, where nearby is defined with a mile radius range
    nearby_miles    = 20
    @nearby_cities  = City.exclude(@city).within_state(@state).all(:origin => @city, :within => nearby_miles) unless @city.blank?

    # build search title based on [what, filter] and city, neighborhood, zip search
    @title          = build_search_title(:what => @what, :filter => @filter, :city => @city, :neighborhood => @neighborhood, :zip => @zip, :state => @state)
    @h1             = @title
    
    # build search object
    @search         = Search.parse([@country, @state, @city, @neighborhood, @zip], @what)
    @tags           = @search.place_tags
    @sphinx_query   = @search.field(:place_tags)

    # use 'what' param to search name and place_tags fields
    # use 'where' param as locality_tags field filter - this is the old way
    # use 'where' param as locality_hash conditions filter
    # use filter' to narrow search conditions
    @conditions     = @search.field(:locality_hash)

    case @filter
    when 'recommended'
      @conditions.update(:recommendations => 1..2**30)
    end

    @locations      = Location.search(@sphinx_query,
                                      :conditions => @conditions, 
                                      :include => [:places, :city, :state, :zip],
                                      :order => :search_rank, :sort_mode => :desc,
                                      :page => params[:page], :per_page => 20)


    if @city or @zip
      # build facets for a city or zip search
      # @facets = Location.facets(@sphinx_query, :conditions => @conditions)
      @facets = Location.facets(@sphinx_query, :conditions => @conditions, :facets => ["city_id", "zip_id", "neighborhood_ids"])

      if @city
        # find related zips
        @zips = Zip.find(@facets[:zip_id].keys)
        
        # find related neighborhoods using faceted search results
        @neighborhoods = Neighborhood.find(@facets[:neighborhood_ids].keys)
      end

      if @zip
        # find related cities
        @cities = City.find(@facets[:city_id].keys)
      end
    end
  end
  
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

end
