class SearchController < ApplicationController
  before_filter   :normalize_page_number, :only => [:index]
  before_filter   :init_localities, :only => [:country, :state, :city, :neighborhood, :zip, :index]

  def country
    # @country, @states initialized in before filter
    @title  = "Search Places and Events in #{@country.name}"
    @h1     = "Search Places and Events by State"
  end

  def state
    # @country, @state, @cities, @zips all initialized in before filter
    
    # partition cities into 2 groups, popular and all
    popular_threshold = 25000
    @popular_cities, @all_cities = @cities.partition do |city|
      city.locations_count > popular_threshold
    end
    
    @title  = "Search Places and Events in #{@state.name}"
    @h1     = "Search Places and Events by City"
  end

  def city
    # @country, @state, @city, @zips and @neighborhoods all initialized in before filter
    
    self.class.benchmark("Benchmarking #{@city.name} tag cloud") do
      @popular_tags = Rails.cache.fetch("#{@city.name.parameterize}:tag_cloud", :expires_in => CacheExpire.tags) do
        # build tag cloud from location and event objects
        tag_limit = 150
        facets    = Location.facets(:with => Search.with(@city), :facets => "tag_ids", :limit => tag_limit, :max_matches => tag_limit)
        tags      = Search.load_from_facets(facets, Tag)#.sort_by { |o| o.name }

        tag_limit = 30
        facets    = Event.facets(:with => Search.with(@city), :facets => "tag_ids", :limit => tag_limit, :max_matches => tag_limit)
        tags      += Search.load_from_facets(facets, Tag)

        # return sorted tags collection
        tags.sort_by { |o| o.name }
      end
    end

    self.class.benchmark("Benchmarking #{@city.name} popular events") do
      @events_count, @popular_events = Rails.cache.fetch("#{@city.name.parameterize}:popular_events", :expires_in => CacheExpire.events) do
        # find city events count and popular events
        event_limit     = 10
        facets          = Event.facets(:with => Search.with(@city), :facets => "city_id", :limit => event_limit, :max_matches => event_limit)
        events_count    = facets[:city_id][@city.id].to_i
        popular_events  = []
        
        [events_count, popular_events]
        # if events_count > 0
        #   # find most popular city events
        #   popular_events = Event.search(:with => Search.with(@city).update(:popularity => 1..100), :limit => 5)
        # end
      end
    end
    
    @title        = "#{@city.name}, #{@state.name} Yellow Pages"
    @h1           = "Search Places and Events in #{@city.name}, #{@state.name}"
  end

  def neighborhood
    # @country, @state, @city, @neighborhood all initialized in before filter

    self.class.benchmark("Benchmarking #{@neighborhood.name} tag cloud") do
      @popular_tags = Rails.cache.fetch("#{@city.name.parameterize}:#{@neighborhood.name.parameterize}:tag_cloud", :expires_in => CacheExpire.tags) do
        # build tag cloud
        tag_limit = 150
        facets    = Location.facets(:with => Search.with(@neighborhood), :facets => "tag_ids", :limit => tag_limit, :max_matches => tag_limit)
        Search.load_from_facets(facets, Tag).sort_by { |o| o.name }
      end
    end

    self.class.benchmark("Benchmarking #{@neighborhood.name} popular events") do
      # find events count and popular events
      event_limit   = 10
      @facets       = Event.facets(:with => Search.with(@neighborhood), :facets => "city_id", :limit => event_limit, :max_matches => event_limit)
      @events_count = @facets[:city_id][@city.id].to_i
    end
    
    @title  = "#{@neighborhood.name}, #{@city.name}, #{@state.name} Yellow Pages"
    @h1     = "Search Places and Events in #{@neighborhood.name}, #{@city.name}, #{@state.name}"
  end

  def zip
    # @country, @state, @zip and @cities all initialized in before filter

    self.class.benchmark("Benchmarking #{@zip.name} tag cloud") do
      @popular_tags = Rails.cache.fetch("#{@zip.name}:tag_cloud", :expires_in => CacheExpire.tags) do
        # build tag cloud
        tag_limit = 150
        facets    = Location.facets(:with => Search.with(@zip), :facets => "tag_ids", :limit => tag_limit, :max_matches => tag_limit)
        Search.load_from_facets(facets, Tag).sort_by { |o| o.name }
      end
    end

    @title        = "#{@state.name} #{@zip.name} Yellow Pages"
    @h1           = "Search Places and Events in #{@state.name} #{@zip.name}"
  end
  
  def index
    # @country, @state, @city, @zip, @neighborhood all initialized in before filter
    
    @search_klass   = params[:klass]
    @tag            = params[:tag].to_s.from_url_param
    @what           = params[:what].to_s.from_url_param
    
    # handle special case of 'something' to find a random what
    @what           = Tag.all(:order => 'rand()', :limit => 1).first.name if @what == 'something'

    @raw_query      = @tag.blank? ? @what : @tag
    @search         = Search.parse([@country, @state, @city, @neighborhood, @zip], @raw_query)
    @query          = @search.query
    @with           = @search.field(:locality_hash)
    
    case @search_klass
    when 'search'
      @klasses = [Event, Location]
    when 'locations'
      @klasses = [Location]
    when 'events'
      @klasses = [Event]
    end

    self.class.benchmark("Benchmarking query '#{@query}'") do
      @objects = ThinkingSphinx::Search.search(@query, :classes => @klasses, :with => @with, :page => params[:page], :per_page => 5,
                                               :order => :popularity, :sort_mode => :desc)
    end

    # filter objects by class if this was a generic search
    @search_filters = Hash.new([])
    @objects.each do |object|
      @search_filters[object.class.to_s] += [object]
    end if @search_klass == 'search'
    
    self.class.benchmark("Benchmarking related search tags") do
      # find related tags by class
      related_size    = 11
      @related_tags   = @klasses.inject([]) do |array, klass|
        facets  = klass.facets(@query, :with => @with, :facets => ["tag_ids"], :limit => related_size, :max_matches => related_size)
        array  += Search.load_from_facets(facets, Tag).collect(&:name).sort - [@raw_query]
      end
    end
    
    self.class.benchmark("Benchmarking related cities, zips, neighborhoods") do
      if @neighborhood
        # build neighborhood cities
        @cities = Array(@neighborhood.city)
        # build zip facets
        limit   = 10
        @facets = Location.facets(@query, :with => @with, :facets => ["zip_id"], :limit => limit, :max_matches => limit)
        @zips   = Search.load_from_facets(@facets, Zip)
      elsif @city
        # build zip and neighborhood facets
        limit           = 10
        @facets         = Location.facets(@query, :with => @with, :facets => ["zip_id", "neighborhood_ids"], :limit => limit, :max_matches => limit)
        @zips           = Search.load_from_facets(@facets, Zip)
        @neighborhoods  = Search.load_from_facets(@facets, Neighborhood)

        # find nearby cities, where nearby is defined with a mile radius range
        nearby_miles    = 20
        nearby_limit    = 5
        @nearby_cities  = City.exclude(@city).within_state(@state).all(:origin => @city, :within => nearby_miles, :order => "distance ASC", :limit => nearby_limit)
      elsif @zip
        # build city facets
        limit   = 5
        @facets = Location.facets(@query, :with => @with, :facets => ["city_id"], :limit => limit, :max_matches => limit)
        @cities = Search.load_from_facets(@facets, City)
      end
    end
    
    @locality_params = {:country => @country, :state => @state, :city => @city, :zip => @zip, :neighborhood => @neighborhood}
    
    # build search title based on what, city, neighborhood, zip search
    @title          = build_search_title(:tag => @tag, :what => @what, :city => @city, :neighborhood => @neighborhood, :zip => @zip, :state => @state)
    @h1             = @title

    # enable/disable robots
    if @search_klass == 'search' and params[:page].to_i == 0
      @robots = true
    else
      @robots = false
    end

    # track what event
    track_what_ga_event(@search_klass, :tag => @tag, :what => @what)
  end
  
  def resolve
    # check search_klass parameter
    @klass    = params[:search_klass] ? params[:search_klass] : 'search'
    # resolve where parameter
    @locality = Locality.resolve(params[:where].to_s)
    # normalize what parameter
    @what     = Search.normalize(params[:what].to_s).parameterize
    
    if @locality.blank?
      redirect_to(:action => 'error', :locality => 'unknown') and return
    end

    case @locality.class.to_s
    when 'City'
      @state    = @locality.state
      @country  = @state.country
      redirect_to(:action => 'index', :klass => @klass, :country => @country, :state => @state, :city => @locality, :what => @what) and return
    when 'Zip'
      @state    = @locality.state
      @country  = @state.country
      redirect_to(:action => 'index', :klass => @klass, :country => @country, :state => @state, :zip => @locality, :what => @what) and return
    when 'Neighborhood'
      @city     = @locality.city
      @state    = @city.state
      @country  = @state.country
      redirect_to(:action => 'index', :klass => @klass, :country => @country, :state => @state, :city => @city, :neighborhood => @locality, :what => @what) and return
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