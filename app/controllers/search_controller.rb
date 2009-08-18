class SearchController < ApplicationController
  before_filter   :normalize_page_number, :only => [:index]
  before_filter   :init_localities, :only => [:country, :state, :city, :neighborhood, :zip, :index]
  before_filter   :init_weather, :only => [:index]

  def country
    # @country, @states initialized in before filter
    @title  = "Search Places and Events in #{@country.name}"
    @h1     = "Search Places and Events by State"
  end

  def state
    # @country, @state, @cities, @zips all initialized in before filter
    
    # partition cities into 2 groups, popular and all
    popular_threshold = City.popular_density
    @popular_cities, @all_cities = @cities.partition do |city|
      city.locations_count > popular_threshold
    end
    
    @title  = "Search Places and Events in #{@state.name}"
    @h1     = "Search Places and Events by City"
  end

  def city
    # @country, @state, @city, @zips and @neighborhoods all initialized in before filter
    
    self.class.benchmark("Benchmarking #{@city.name} tag cloud") do
      @popular_tags = Rails.cache.fetch("#{@state.code}:#{@city.name.parameterize}:tag_cloud", :expires_in => CacheExpire.tags) do
        # build tag cloud from (cached) geo tag counts in the database
        tags = @city.tags
        # return sorted, unique tags collection
        tags.sort_by { |o| o.name }.uniq
      end
    end

    @title  = "#{@city.name}, #{@state.code} Yellow Pages"
    @h1     = "Search Places and Events in #{@city.name}, #{@state.name}"
  end

  def neighborhood
    # @country, @state, @city, @neighborhood all initialized in before filter

    self.class.benchmark("Benchmarking #{@neighborhood.name} tag cloud") do
      @popular_tags = Rails.cache.fetch("#{@state.code}:#{@city.name.parameterize}:#{@neighborhood.name.parameterize}:tag_cloud", :expires_in => CacheExpire.tags) do
        # build tag cloud from (cached) geo tag counts in the database
        tags = @neighborhood.tags
        # use city tags if there are no neighborhood tags
        tags = @city.tags if tags.empty?
        # return sorted, unique tags collection
        tags.sort_by { |o| o.name }.uniq
      end
    end

    @title  = "#{@neighborhood.name}, #{@city.name}, #{@state.code} Yellow Pages"
    @h1     = "Search Places and Events in #{@neighborhood.name}, #{@city.name}, #{@state.name}"
  end

  def zip
    # @country, @state, @zip, @cities, and @city all initialized in before filter

    self.class.benchmark("Benchmarking #{@zip.name} tag cloud") do
      @popular_tags = Rails.cache.fetch("#{@state.code}:#{@zip.name}:tag_cloud", :expires_in => CacheExpire.tags) do
        # build tag cloud from (cached) geo tag counts in the database
        tags = @zip.tags
        # use city tags if there are no zip tags
        tags = @city.tags if tags.blank? and !@city.blank?
        # return sorted, unique tags collection
        tags.sort_by { |o| o.name }.uniq
      end
    end

    @title  = "#{@state.code} #{@zip.name} Yellow Pages"
    @h1     = "Search Places and Events in #{@state.code} #{@zip.name}"
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
      # search Appointment class only if there are events
      @klasses        = @events_count > 0 ? [Appointment, Location] : [Location]
      @eager_loads    = @events_count > 0 ? [] : [:company, :city, :state, :zip, :primary_phone_number]
      @facet_klass    = Location
      @sort_order     = :popularity
      @sort_mode      = :desc
    when 'locations'
      @klasses        = [Location]
      @eager_loads    = [:company, :city, :state, :zip, :primary_phone_number]
      @facet_klass    = Location
      @sort_order     = :popularity
      @sort_mode      = :desc
    when 'events'
      @klasses        = [Appointment]
      @eager_loads    = [{:location => :company}]
      @facet_klass    = Appointment
      @sort_order     = :start_at
      @sort_mode      = :asc
    end

    self.class.benchmark("*** Benchmarking sphinx query '#{@query_or}'", Logger::INFO, false) do
      @objects = ThinkingSphinx::Search.search(@query_or, :classes => @klasses, :with => @attributes, :conditions => @fields,
                                               :match_mode => :extended2, :rank_mode => :bm25, :page => params[:page], :per_page => 5,
                                               :order => @sort_order, :sort_mode => @sort_mode, :include => @eager_loads)
    end

    # filter objects by class if this was a generic search
    @search_filters = Hash.new([])
    @objects.each do |object|
      @search_filters[object.class.to_s] += [object]
    end if @search_klass == 'search'
    
    self.class.benchmark("*** Benchmarking sphinx facets tags for '#{@query_and}'", Logger::INFO, false) do
      # find related tags by class; build tag facets for each klass
      related_size    = 11
      @related_tags   = @klasses.inject([]) do |array, klass|
        facets  = klass.facets(@query_and, :with => @attributes, :facets => ["tag_ids"], :match_mode => :extended2, :limit => related_size)
        self.class.benchmark("*** benchmarking ... tag database load", Logger::INFO) do
          array  += Search.load_from_facets(facets, Tag).collect(&:name).sort - [@query_raw]
        end
      end
    end

    if @neighborhood
      self.class.benchmark("** Benchmarking sphinx facets #{@neighborhood.name} neighborhoods for '#{@query_and}'", Logger::INFO, false) do
        @geo_type       = 'neighborhood'

        # build neighborhood cities
        @cities         = Array(@neighborhood.city)

        # SK: comment out zip facets for neighborhood searches
        # build zip facets using all geo constraints
        # limit           = 10
        # facet_ids       = ["zip_id"]
        # facets          = @facet_klass.facets(@query_and, :with => @attributes, :facets => facet_ids, :match_mode => :extended2, :limit => limit)
        # @zips           = Search.load_from_facets(facets, Zip)

        # build neighborhood facets using only city constraint
        limit           = 11
        facet_ids       = ["neighborhood_ids"]
        with_city       = Search.attributes(@city).update(@hash[:attributes] || Hash[])
        facets          = @facet_klass.facets(@query_and, :with => with_city, :facets => facet_ids, :match_mode => :extended2, :limit => limit)
        @neighborhoods  = (Search.load_from_facets(facets, Neighborhood) - Array[@neighborhood]).sort_by{ |o| o.name }
      end
    elsif @city
      self.class.benchmark("*** Benchmarking sphinx facets #{@city.name} neighborhoods for '#{@query_and}'", Logger::INFO, false) do
        @geo_type       = 'city'

        # SK: comment out zip facets for city searches
        # build neighborhood facets iff city has neighborhoods, based on search klass
        limit           = 10
        # facet_ids       = @city.neighborhoods_count > 0 ? ["zip_id", "neighborhood_ids"] : ["zip_id"]
        facet_ids       = @city.neighborhoods_count > 0 ? ["neighborhood_ids"] : []
        facets          = @facet_klass.facets(@query_and, :with => @attributes, :facets => facet_ids, :match_mode => :extended2, :limit => limit)
        
        self.class.benchmark("*** benchmarking ... neighborhood database load", Logger::INFO) do
          @zips           = Search.load_from_facets(facets, Zip) if facet_ids.include?("zip_id")
          @neighborhoods  = Search.load_from_facets(facets, Neighborhood).sort_by{ |o| o.name } if facet_ids.include?("neighborhood_ids")
        end
        
        # SK: this is an optimization to cache zip and neighborhood facets for a specific search, but requires more testing
        # @zips, @neighborhoods = Rails.cache.fetch("#{@city.name.parameterize}:#{@facet_klass.to_s.parameterize}:#{@query_raw.parameterize}:facets:zips:neighborhoods", :expires_in => CacheExpire.facets) do
        #   facets          = @facet_klass.facets(@query_and, :with => @attributes, :facets => ["zip_id", "neighborhood_ids"], :limit => limit)
        #   zips            = Search.load_from_facets(facets, Zip)
        #   neighborhoods   = Search.load_from_facets(facets, Neighborhood).sort_by{ |o| o.name }
        #   [zips, neighborhoods]
        # end

        self.class.benchmark("*** Benchmarking #{@city.name} nearby cities", Logger::INFO, false) do
          # find (and cache) nearby cities, where nearby is defined with a mile radius range
          nearby_miles    = 20
          nearby_limit    = 5
          @nearby_cities  = Rails.cache.fetch("#{@state.code}:#{@city.name.parameterize}:nearby:cities", :expires_in => CacheExpire.localities) do
            City.exclude(@city).within_state(@state).all(:origin => @city, :within => nearby_miles, :order => "distance ASC", :limit => nearby_limit)
          end
        end
      end
    elsif @zip
      self.class.benchmark("Benchmarking sphinx facets #{@zip.name} cities for '#{@query_and}'", Logger::INFO, false) do
        @geo_type   = 'zip'

        # build city facets
        limit       = 5
        facets      = @facet_klass.facets(@query_and, :with => @attributes, :facets => ["city_id"], :match_mode => :extended2, :limit => limit)
        @cities     = Search.load_from_facets(facets, City)
      end
    end

    @geo_params = {:country => @country, :state => @state, :city => @city, :zip => @zip, :neighborhood => @neighborhood}
    
    # build search title based on query, city, neighborhood, zip search
    @title  = build_search_title(:tag => @tag, :query => @query, :city => @city, :neighborhood => @neighborhood, :zip => @zip, :state => @state)
    @h1     = @title

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
    @where    = params[:where].to_s
    @locality = Locality.search(@where, :log => true) || Locality.resolve(@where)
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