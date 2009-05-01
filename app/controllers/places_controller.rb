class PlacesController < ApplicationController
  before_filter   :normalize_page_number, :only => [:index]
  before_filter   :init_localities, :only => [:country, :state, :city, :neighborhood, :zip, :index]
  
  def country
    # @country, @states initialized in before filter
    @title  = "Browse Places in #{@country.name}"
    @h1     = "Browse Places by State"
  end
      
  def state
    # @country, @state, @cities, @zips all initialized in before filter
    @title  = "Browse Places in #{@state.name}"
    @h1     = @title
  end
    
  def city
    # @country, @state, @city, @zips and @neighborhoods all initialized in before filter
    
    # generate popular tag counts
    options       = {:with => Search.with(@city)}.update(Search.tag_group_options(150))
    @facets       = Location.facets(options)
    @popular_tags = Search.load_from_facets(@facets, Tag).sort_by { |o| o.name }
    
    @title        = "Browse Places in #{@city.name}, #{@state.name}"
    @h1           = @title
  end

  def neighborhood
    # @country, @state, @city, @neighborhood all initialized in before filter

    # generate popular tag counts
    options       = {:with => Search.with(@city)}.update(Search.tag_group_options(150))
    @facets       = Location.facets(options)
    @popular_tags = Search.load_from_facets(@facets, Tag).sort_by { |o| o.name }
    
    @title        = "Browse Places in #{@neighborhood.name}, #{@city.name}, #{@state.name}"
    @h1           = @title
  end
  
  def zip
    # @country, @state, @zip and @cities all initialized in before filter

    # generate popular tag counts
    options       = {:with => Search.with(@city)}.update(Search.tag_group_options(150))
    @facets       = Location.facets(options)
    @popular_tags = Search.load_from_facets(@facets, Tag).sort_by { |o| o.name }
    
    @title        = "Browse Places in #{@state.name} #{@zip.name}"
    @h1           = @title
  end
    
  def index
    # @country, @state, @city, @zip, @neighborhood all initialized in before filter
    
    @tag            = params[:tag].to_s.from_url_param
    @what           = params[:what].to_s.from_url_param
    @filter         = params[:filter].to_s.from_url_param if params[:filter]
    
    # handle special case of 'something' to find a random what
    @what           = Tag.all(:order => 'rand()', :limit => 1).first.name if @what == 'something'

    # build search object
    # use 'tag' or 'what' param to build search query
    # use 'where' param as locality_hash with/conditions filter
    # use filter' to narrow search conditions
    @search         = Search.parse([@country, @state, @city, @neighborhood, @zip], @tag.blank? ? @what : @tag)
    @tags           = @search.place_tags
    @query          = @search.query
    @with           = Search.with(@country, @state, @city, @neighborhood, @zip)

    case @filter
    when 'recommended'
      @conditions.update(:recommendations => 1..2**30)
    end

    @locations      = Location.search(@query,
                                      :with => @with, 
                                      :include => [:places, :city, :state, :zip],
                                      :order => :popularity, :sort_mode => :desc,
                                      :page => params[:page], :per_page => 20)


    if @city or @zip
      # build facets for city or zip searches
      @facets = Location.facets(@sphinx_query, :with => @with, :facets => ["city_id", "zip_id", "neighborhood_ids"])

      if @city
        # find zips and neighborhoods facet
        @zips           = Search.load_from_facets(@facets, Zip)
        @neighborhoods  = Search.load_from_facets(@facets, Neighborhood)
      end

      if @zip
        # find cities facet
        @cities = Search.load_from_facets(@facets, City)
      end
    end
    
    # find nearby cities if its a city search, where nearby is defined with a mile radius range
    nearby_miles    = 20
    nearby_limit    = 10
    @nearby_cities  = City.exclude(@city).within_state(@state).all(:origin => @city, :within => nearby_miles, :order => "distance ASC", :limit => nearby_limit) unless @city.blank?

    # build search title based on [what, filter] and city, neighborhood, zip search
    @title  = build_search_title(:what => @what, :tag => @tag, :filter => @filter, :city => @city, :neighborhood => @neighborhood, :zip => @zip, :state => @state)
    @h1     = @title

    # track what event
    track_what_ga_event(params[:controller], :tag => @tag, :what => @what)
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
    @title    = "Places Search Error"
    
    render(:template => 'search/error')
  end

end
