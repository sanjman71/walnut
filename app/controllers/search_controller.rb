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
        facets    = Location.facets(:with => Search.attributes(@city), :facets => "tag_ids", :limit => tag_limit, :max_matches => tag_limit)
        tags      = Search.load_from_facets(facets, Tag)#.sort_by { |o| o.name }

        tag_limit = 30
        facets    = Event.facets(:with => Search.attributes(@city), :facets => "tag_ids", :limit => tag_limit, :max_matches => tag_limit)
        tags      += Search.load_from_facets(facets, Tag)

        # return sorted, unique tags collection
        tags.sort_by { |o| o.name }.uniq
      end
    end

    self.class.benchmark("Benchmarking #{@city.name} events") do
      @events_count = Rails.cache.fetch("#{@city.name.parameterize}:events", :expires_in => CacheExpire.events) do
        # find city events count
        facets = Event.facets(:with => Search.attributes(@city), :facets => "city_id")
        facets[:city_id][@city.id].to_i
      end
    end
    
    @title        = "#{@city.name}, #{@state.name} Yellow Pages"
    @h1           = "Search Places and Events in #{@city.name}, #{@state.name}"
  end

  def neighborhood
    # @country, @state, @city, @neighborhood all initialized in before filter

    self.class.benchmark("Benchmarking #{@neighborhood.name} tag cloud") do
      @popular_tags = Rails.cache.fetch("#{@city.name.parameterize}:#{@neighborhood.name.parameterize}:tag_cloud", :expires_in => CacheExpire.tags) do
        # build tag cloud from location and event objects
        tag_limit = 150
        facets    = Location.facets(:with => Search.attributes(@neighborhood), :facets => "tag_ids", :limit => tag_limit, :max_matches => tag_limit)
        tags      = Search.load_from_facets(facets, Tag).sort_by { |o| o.name }

        tag_limit = 30
        facets    = Event.facets(:with => Search.attributes(@neighborhood), :facets => "tag_ids", :limit => tag_limit, :max_matches => tag_limit)
        tags      += Search.load_from_facets(facets, Tag)

        # return sorted, unique tags collection
        tags.sort_by { |o| o.name }.uniq
      end
    end

    self.class.benchmark("Benchmarking #{@neighborhood.name} events") do
      # find neighborhood events count
      @events_count = Rails.cache.fetch("#{@city.name.parameterize}:#{@neighborhood.name.parameterize}:events", :expires_in => CacheExpire.events) do
        facets = Event.facets(:with => Search.attributes(@neighborhood), :facets => "neighborhood_ids")
        facets[:neighborhood_ids][@neighborhood.id].to_i
      end
    end
    
    @title  = "#{@neighborhood.name}, #{@city.name}, #{@state.name} Yellow Pages"
    @h1     = "Search Places and Events in #{@neighborhood.name}, #{@city.name}, #{@state.name}"
  end

  def zip
    # @country, @state, @zip and @cities all initialized in before filter

    self.class.benchmark("Benchmarking #{@zip.name} tag cloud") do
      @popular_tags = Rails.cache.fetch("#{@zip.name}:tag_cloud", :expires_in => CacheExpire.tags) do
        # build tag cloud from location and event objects
        tag_limit = 150
        facets    = Location.facets(:with => Search.attributes(@zip), :facets => "tag_ids", :limit => tag_limit, :max_matches => tag_limit)
        tags      = Search.load_from_facets(facets, Tag).sort_by { |o| o.name }

        tag_limit = 30
        facets    = Event.facets(:with => Search.attributes(@zip), :facets => "tag_ids", :limit => tag_limit, :max_matches => tag_limit)
        tags      += Search.load_from_facets(facets, Tag)

        # return sorted, unique tags collection
        tags.sort_by { |o| o.name }.uniq
      end
    end

    @title        = "#{@state.name} #{@zip.name} Yellow Pages"
    @h1           = "Search Places and Events in #{@state.name} #{@zip.name}"
  end
  
  def index
    # @country, @state, @city, @zip, @neighborhood all initialized in before filter
    
    @search_klass   = params[:klass]
    @tag            = params[:tag].to_s.from_url_param
    @query          = params[:query] ? session[:query] : ''

    if @tag.blank? and @query.blank?
      # default to tag 'anything'
      redirect_to(url_for(:query => nil, :tag => 'anything')) and return
    end

    # handle special case of 'something' to find a random tag
    @tag            = Tag.all(:order => 'rand()', :limit => 1).first.name if @tag == 'something'

    @hash           = Search.query(!@tag.blank? ? @tag : @query)
    @query_raw      = @hash[:query_raw]
    @query_or       = @hash[:query_or]
    @query_and      = @hash[:query_and]
    @fields         = @hash[:fields]
    @attributes     = @hash[:attributes] || Hash.new
    @attributes     = Search.attributes(@country, @state, @city, @neighborhood, @zip).update(@attributes)

    case @search_klass
    when 'search'
      @klasses    = [Event, Location]
      @sort_order = :popularity
      @sort_mode  = :desc
    when 'locations'
      @klasses    = [Location]
      @sort_order = :popularity
      @sort_mode  = :desc
    when 'events'
      @klasses    = [Event]
      @sort_order = :start_at
      @sort_mode  = :asc
    end

    self.class.benchmark("Benchmarking query '#{@query_or}'") do
      @objects = ThinkingSphinx::Search.search(@query_or, :classes => @klasses, :with => @attributes, :conditions => @fields,
                                               :match_mode => :extended, :page => params[:page], :per_page => 5,
                                               :order => @sort_order, :sort_mode => @sort_mode)
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
        facets  = klass.facets(@query_and, :with => @attributes, :facets => ["tag_ids"], :limit => related_size, :max_matches => related_size)
        array  += Search.load_from_facets(facets, Tag).collect(&:name).sort - [@query_raw]
      end
    end
    
    self.class.benchmark("Benchmarking related cities, zips, neighborhoods") do
      if @neighborhood
        @locality_type    = 'neighborhood'

        # build neighborhood cities
        @cities           = Array(@neighborhood.city)

        # build zip facets using all locality constraints
        limit             = 10
        facets            = Location.facets(@query_and, :with => @attributes, :facets => ["zip_id"], :limit => limit, :max_matches => limit)
        @zips             = Search.load_from_facets(facets, Zip)

        # build neighborhood facets using only city constraint
        limit             = 11
        city_constraints  = Search.attributes(@city).update(@hash[:attributes] || Hash[])
        facets            = Location.facets(@query_and, :with => city_constraints, :facets => ["neighborhood_ids"], :limit => limit, :max_matches => limit)
        @neighborhoods    = (Search.load_from_facets(facets, Neighborhood) - Array[@neighborhood]).sort_by{ |o| o.name }
      elsif @city
        @locality_type  = 'city'

        # build zip and neighborhood facets
        limit           = 10
        facets          = Location.facets(@query_and, :with => @attributes, :facets => ["zip_id", "neighborhood_ids"], :limit => limit, :max_matches => limit)
        @zips           = Search.load_from_facets(facets, Zip)
        @neighborhoods  = Search.load_from_facets(facets, Neighborhood).sort_by{ |o| o.name }

        # find nearby cities, where nearby is defined with a mile radius range
        nearby_miles    = 20
        nearby_limit    = 5
        @nearby_cities  = City.exclude(@city).within_state(@state).all(:origin => @city, :within => nearby_miles, :order => "distance ASC", :limit => nearby_limit)
      elsif @zip
        @locality_type  = 'zip'

        # build neighborhood and city facets
        limit           = 5
        facets          = Location.facets(@query_and, :with => @attributes, :facets => ["city_id"], :limit => limit, :max_matches => limit)
        @cities         = Search.load_from_facets(facets, City)
      end
    end
    
    @locality_params = {:country => @country, :state => @state, :city => @city, :zip => @zip, :neighborhood => @neighborhood}
    
    # build search title based on query, city, neighborhood, zip search
    @title          = build_search_title(:tag => @tag, :query => @query, :city => @city, :neighborhood => @neighborhood, :zip => @zip, :state => @state)
    @h1             = @title

    # enable/disable robots
    if @search_klass == 'search' and params[:page].to_i == 0 and !@tag.blank?
      @robots = true
    else
      @robots = false
    end

    # track what event
    track_what_ga_event(@search_klass, :tag => @tag, :query => @query)

    if @objects.blank?
      # no search results
      render(:action => 'no_results')
    else
      render(:action => 'index')
    end
  end
  
  def resolve
    # check search_klass parameter
    @klass    = params[:search_klass] ? params[:search_klass] : 'search'
    # resolve where parameter
    @locality = Locality.resolve(params[:where].to_s)
    # normalize query parameter
    @query    = Search.normalize(params[:query].to_s).parameterize
    # @query    = 'query'

    # store raw query as a session parameter
    session[:query] = params[:query].to_s
    
    if @locality.blank?
      redirect_to(:action => 'error', :locality => 'unknown') and return
    end

    case @locality.class.to_s
    when 'City'
      @state    = @locality.state
      @country  = @state.country
      redirect_to(:action => 'index', :klass => @klass, :country => @country, :state => @state, :city => @locality, :query => @query) and return
    when 'Zip'
      @state    = @locality.state
      @country  = @state.country
      redirect_to(:action => 'index', :klass => @klass, :country => @country, :state => @state, :zip => @locality, :query => @query) and return
    when 'Neighborhood'
      @city     = @locality.city
      @state    = @city.state
      @country  = @state.country
      redirect_to(:action => 'index', :klass => @klass, :country => @country, :state => @state, :city => @city, :neighborhood => @locality, :query => @query) and return
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