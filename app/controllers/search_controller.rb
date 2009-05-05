class SearchController < ApplicationController
  before_filter   :normalize_page_number, :only => [:index]
  before_filter   :init_localities, :only => [:country, :state, :city, :index]

  def country
    # @country, @states initialized in before filter
    @title  = "Browse Places and Events in #{@country.name}"
    @h1     = "Browse Places and Events by State"
  end

  def state
    # @country, @state, @cities, @zips all initialized in before filter
    @title  = "Browse Places and Events in #{@state.name}"
    @h1     = @title
  end

  def city
    # @country, @state, @city, @zips and @neighborhoods all initialized in before filter
    
    self.class.benchmark("Benchmarking #{@city.name} tag cloud") do
      # build city tag cloud
      tag_limit     = 150
      @facets       = Location.facets(:with => Search.with(@city), :facets => "tag_ids", :limit => tag_limit, :max_matches => tag_limit)
      @popular_tags = Search.load_from_facets(@facets, Tag).sort_by { |o| o.name }
    end
    
    self.class.benchmark("Benchmarking #{@city.name} popular events") do
      # find city events count and popular events
      event_limit   = 10
      @facets       = Event.facets(:with => Search.with(@city), :facets => "city_id", :limit => event_limit, :max_matches => event_limit)
      @events_count = @facets[:city_id][@city.id].to_i
    
      # if @events_count > 0
      #   # find most popular city events
      #   @with           = Search.with(@city).update(:popularity => 1..100)
      #   @popular_events = Event.search(:with => @with, :limit => 5)
      # else
      #   # no popular events
      #   @popular_events = []
      # end
    end
    
    @title        = "#{@city.name}, #{@state.name} Yellow Pages"
    @h1           = "Search Places and Events in #{@city.name}, #{@state.name}"
  end

  def index
    # @country, @state, @city, @zip, @neighborhood all initialized in before filter
    
    @tag            = params[:tag].to_s.from_url_param
    @what           = params[:what].to_s.from_url_param
    
    # handle special case of 'something' to find a random what
    @what           = Tag.all(:order => 'rand()', :limit => 1).first.name if @what == 'something'

    @raw_query      = @tag.blank? ? @what : @tag
    @search         = Search.parse([@country, @state, @city, @neighborhood, @zip], @raw_query)
    @query          = @search.query
    @with           = @search.field(:locality_hash)

    self.class.benchmark("Benchmarking query '#{@query}'") do
      @objects      = ThinkingSphinx::Search.search(@query, :classes => [Event, Location], :with => @with, :page => params[:page], :per_page => 5,
                                                    :order => :popularity, :sort_mode => :desc)
    end
    
    # find objects by class
    @klasses        = Hash.new([])
    @objects.each do |object|
      @klasses[object.class.to_s] += [object]
    end

    self.class.benchmark("Benchmarking related search tags") do
      # find related tags by class
      related_size    = 11
      @related_tags   = [Location, Event].inject([]) do |array, klass|
        facets  = klass.facets(@query, :with => Search.with(@city), :facets => ["tag_ids"], :limit => related_size, :max_matches => related_size)
        array  += Search.load_from_facets(facets, Tag).collect(&:name) - [@raw_query]
      end
    end
    
    self.class.benchmark("Benchmarking related cities, zips, neighborhoods") do
      if @city
        # build zip and neighborhood facets
        @facets         = Location.facets(@query, :with => @with, :facets => ["zip_id", "neighborhood_ids"])
        @zips           = Search.load_from_facets(@facets, Zip)
        @neighborhoods  = Search.load_from_facets(@facets, Neighborhood)

        # find nearby cities, where nearby is defined with a mile radius range
        nearby_miles    = 20
        nearby_limit    = 5
        @nearby_cities  = City.exclude(@city).within_state(@state).all(:origin => @city, :within => nearby_miles, :order => "distance ASC", :limit => nearby_limit)
      elsif @zip
        # build city facets
        @facets = Location.facets(@query, :with => @with, :facets => ["city_id"])
        @cities = Search.load_from_facets(@facets, City)
      end
    end
    
    @locality_params = {:country => @country, :state => @state, :city => @city, :zip => @zip, :neighborhood => @neighborhood}
    
    # build search title based on what, city, neighborhood, zip search
    @title          = build_search_title(:tag => @tag, :what => @what, :city => @city, :neighborhood => @neighborhood, :zip => @zip, :state => @state)
    @h1             = @title

    # track what event
    track_what_ga_event(params[:controller], :tag => @tag, :what => @what)
  end
  
  def resolve
    # resolve where parameter
    @locality = Locality.resolve(params[:where].to_s)
    @what     = params[:what].to_s.parameterize
    
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
      raise Exception, "search by state not supported"
    else
      redirect_to(root_path)
    end
  end
  
  def error
    @title  = "Search Error"
  end
  
end