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
      @popular_tags = Rails.cache.fetch("#{@state.code.downcase}:#{@city.name.to_url_param}:tag_cloud", :expires_in => CacheExpire.tags) do
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
      @popular_tags = Rails.cache.fetch("#{@state.code.downcase}:#{@city.name.to_url_param}:#{@neighborhood.name.to_url_param}:tag_cloud", :expires_in => CacheExpire.tags) do
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
      @popular_tags = Rails.cache.fetch("#{@state.code.downcase}:#{@zip.name}:tag_cloud", :expires_in => CacheExpire.tags) do
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
    @tag            = find_tag(params[:tag].to_s.from_url_param)
    @query          = find_query

    if @tag.blank? and @query.blank?
      # default to query 'anything'
      redirect_to(url_for(:query => 'anything', :tag => nil)) and return
    end

    # handle special case of 'something' to find a random tag
    @tag            = find_random_tag if @tag == 'something'

    @hash           = Search.query(!@tag.blank? ? Search.build_field_query("tags", @tag.name) : @query)
    @query_raw      = @hash[:query_raw]
    @query_or       = @hash[:query_or]
    @query_and      = @hash[:query_and]
    @query_quorum   = @hash[:query_quorum]
    @fields         = @hash[:fields]
    @attributes     = @hash[:attributes] || Hash.new
    @max_matches    = 50 # limit the total number of results

    # build attributes based on geo type
    case
    when @neighborhood
      @attributes = Search.attributes(@neighborhood).update(@attributes)
      @geo_search = 'neighborhood'
    when @city
      @attributes = Search.attributes(@city).update(@attributes)
      @geo_search = 'city'
    when @zip
      @attributes = Search.attributes(@zip).update(@attributes)
      @geo_search = 'zip'
    end

    case @search_klass
    when 'search'
      # search Appointment class iff there are events
      # @klasses        = @events_count > 0 ? [Appointment, Location] : [Location]
      # only eager load if we know the klass type
      # @eager_loads    = @events_count > 0 ? [] : [:company, :city, :state, :zip, :primary_phone_number]

      # search returns location results until the eager loading performance issue is addressed
      @klasses        = [Location]
      @eager_loads    = [{:company => :tags}, :city, :state, :zip, :primary_phone_number]
      @facet_klass    = Location
      @tag_klasses    = [Location]
      @sort_order     = "popularity desc, @relevance desc"
    when 'locations'
      @klasses        = [Location]
      @eager_loads    = [{:company => :tags}, :city, :state, :zip, :primary_phone_number]
      @facet_klass    = Location
      @tag_klasses    = [Location]
      @sort_order     = "popularity desc, @relevance desc"
    when 'events'
      @klasses        = [Appointment]
      @eager_loads    = [{:location => :company}, :tags]
      @facet_klass    = Appointment
      @tag_klasses    = [Location]
      @sort_order     = "start_at asc"
    end

    self.class.benchmark("*** Benchmarking sphinx query", APP_LOGGER_LEVEL, false) do
      @objects = ThinkingSphinx.search(@query_quorum, :classes => @klasses, :with => @attributes, :conditions => @fields,
                                       :match_mode => :extended2, :rank_mode => :bm25, :order => @sort_order, :include => @eager_loads, 
                                       :page => params[:page], :per_page => 5, :max_matches => @max_matches)
      # the first reference to 'objects' does the actual sphinx query 
      logger.debug("*** [sphinx] objects: #{@objects.size}")
    end

    # filter objects by class if this was a generic search
    @search_filters = Hash.new([])
    @objects.each do |object|
      @search_filters[object.class.to_s] += [object]
    end if @search_klass == 'search'

    # self.class.benchmark("*** Benchmarking related tags from sphinx facets", Logger::INFO, false) do
    #   # find related tags by class; build tag facets for each specified tag klass
    #   related_size    = 11
    #   @related_tags   = @tag_klasses.inject([]) do |array, klass|
    #     facets  = klass.facets(@query_and, :with => @attributes, :facets => [:tag_ids], :group_clause => "@count desc", :limit => related_size,
    #                            :match_mode => :extended2)
    #     self.class.benchmark("*** benchmarking ... tag database load", Logger::INFO) do
    #       array  += Search.load_from_facets(facets, Tag).collect(&:name).sort - [@query_raw]
    #     end
    #   end
    # end

    self.class.benchmark("*** Benchmarking related tags from database", APP_LOGGER_LEVEL, false) do
      # find related tags by collecting all object tags from the search results, sort by tag popularity
      related_size   = 10
      @related_tags  = @objects.collect{ |o| o.tags }.flatten.compact.uniq.sort_by{ |o| -o.taggings_count }
      # sort and filter number of tags shown
      @related_tags  = (@related_tags.collect(&:name) - [@tag ? @tag.name : @query_raw]).slice(0, related_size)
    end

    case @geo_search
    when 'neighborhood'
      # self.class.benchmark("*** Benchmarking related #{@neighborhood.name.downcase} neighborhoods from sphinx facets for '#{@query_and}'", Logger::INFO, false) do
      #   # use neighborhood cities as nearby cities
      #   @cities         = Array(@neighborhood.city)
      # 
      #   # SK: comment out zip facets for neighborhood searches
      #   # build zip facets using all geo constraints
      #   # limit           = 10
      #   # facets          = @facet_klass.facets(@query_and, :with => @attributes, :facets => [:zip_id], :group_clause => "@count desc", :match_mode => :extended2, :limit => limit)
      #   # @zips           = Search.load_from_facets(facets, Zip)
      # 
      #   # build neighborhood facets using city constraint
      #   limit           = 11
      #   attr_city       = Search.attributes(@city)
      #   facets          = @facet_klass.facets(@query_and, :with => attr_city, :facets => [:neighborhood_ids], :group_clause => "@count desc",
      #                                         :match_mode => :extended2, :limit => limit)
      #   @neighborhoods  = (Search.load_from_facets(facets, Neighborhood) - Array[@neighborhood]).sort_by{ |o| o.name }
      # end

      self.class.benchmark("*** Benchmarking related #{@neighborhood.name.downcase} neighborhoods from database", APP_LOGGER_LEVEL, false) do
        @neighborhoods = (@objects.collect(&:neighborhoods).flatten.uniq - [@neighborhood])
      end

      self.class.benchmark("*** Benchmarking nearby #{@neighborhood.name.downcase} cities from database", APP_LOGGER_LEVEL, false) do
        @cities = Array(@neighborhood.city)
      end
    when 'city'
      # self.class.benchmark("*** Benchmarking #{@city.name.downcase} neighborhoods from sphinx facets for '#{@query_and}'", Logger::INFO, false) do
      #   # SK: comment out zip facets for city searches
      #   # build neighborhood facets iff city has neighborhoods
      #   if @city.neighborhoods_count > 0
      #     limit     = 20
      #     facets    = @facet_klass.facets(@query_and, :with => @attributes, :facets => [:neighborhood_ids], :group_clause => "@count desc", 
      #                                     :match_mode => :extended2, :limit => limit)
      # 
      #     self.class.benchmark("*** benchmarking ... neighborhood database load", Logger::INFO) do
      #       @neighborhoods = Search.load_from_facets(facets, Neighborhood).sort_by{ |o| o.name }
      #     end
      #   end
      # 
      #   # SK: this is an optimization to cache zip and neighborhood facets for a specific search, but requires more testing
      #   # @zips, @neighborhoods = Rails.cache.fetch("#{@city.name.to_url_param}:#{@facet_klass.to_s.to_url_param}:#{@query_raw.to_url_param}:facets:zips:neighborhoods", :expires_in => CacheExpire.facets) do
      #   #   facets          = @facet_klass.facets(@query_and, :with => @attributes, :facets => ["zip_id", "neighborhood_ids"], :limit => limit)
      #   #   zips            = Search.load_from_facets(facets, Zip)
      #   #   neighborhoods   = Search.load_from_facets(facets, Neighborhood).sort_by{ |o| o.name }
      #   #   [zips, neighborhoods]
      #   # end
      # end

      self.class.benchmark("*** Benchmarking #{@city.name.downcase} neighborhoods from database", APP_LOGGER_LEVEL, false) do
        unless @city.neighborhoods_count == 0
          # SK - can we eager join here like this?
          # @neighborhoods = Location.find(@objects.collect(&:id), :include => :neighborhoods)
          @neighborhoods = @objects.collect(&:neighborhoods).flatten.uniq
        end
      end

      self.class.benchmark("*** Benchmarking #{@city.name.downcase} zips from database", APP_LOGGER_LEVEL, false) do
        @zips = @objects.collect(&:zip).flatten.compact.uniq
      end

      self.class.benchmark("*** Benchmarking #{@city.name.downcase} nearby cities", APP_LOGGER_LEVEL, false) do
        if @neighborhoods.blank?
          # find (and cache) nearby cities, where nearby is defined with a mile radius range, iff there are no neighborhoods
          nearby_miles    = 20
          nearby_limit    = 5
          @nearby_cities  = Rails.cache.fetch("#{@state.code.downcase}:#{@city.name.to_url_param}:nearby:cities", :expires_in => CacheExpire.localities) do
            City.exclude(@city).within_state(@state).all(:origin => @city, :within => nearby_miles, :order => "distance ASC", :limit => nearby_limit)
          end
        end
      end
    when 'zip'
      # self.class.benchmark("*** Benchmarking #{@zip.name} cities from sphinx facets", Logger::INFO, false) do
      #   # build city facets
      #   limit       = 5
      #   facets      = @facet_klass.facets(@query_and, :with => @attributes, :facets => [:city_id], :group_clause => "@count desc", :limit => limit,
      #                                     :match_mode => :extended2)
      #   @cities     = Search.load_from_facets(facets, City)
      # end

      self.class.benchmark("*** Benchmarking #{@zip.name} cities from database", APP_LOGGER_LEVEL, false) do
        @city_ids = @objects.collect(&:city_id).flatten.compact.uniq
        @cities   = City.find(@city_ids)
      end
    end

    @geo_params = {:country => @country, :state => @state, :city => @city, :zip => @zip, :neighborhood => @neighborhood}

    # build search title based on query, city, neighborhood, zip search
    @title  = build_search_title(:tag => @tag.to_s, :query => @query, :city => @city, :neighborhood => @neighborhood, :zip => @zip, :state => @state)
    @h1     = @title

    # set robots flag
    if indexable_klass?(@search_klass) and params[:page].to_i == 0 and indexable_query?(@tag, @query, @objects)
      @robots = true
    else
      @robots = false
    end

    # track what event
    track_what_ga_event(@search_klass, :tag => @tag.to_s, :query => @query)

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
    @query    = Search.normalize(params[:query].to_s).to_url_param
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

  protected

  def find_tag(s)
    return nil if s.blank?
    if ['something'].include?(s)
      find_random_tag
    else
      # find specified tag
      Tag.find_by_name(s)
    end
  end

  def find_query
    # params[:query] ? (session[:query] || params[:query]) : ''
    case
    when (params[:query] and params[:query] == 'anything')
      # the special 'anything' query
      params[:query]
    when params[:query]
      # use session query if one exists, default to params
      session[:query] || params[:query]
    else
      # no query
      ''
    end
  end

  def find_random_tag
    self.class.benchmark("*** Benchmarking find random tag", APP_LOGGER_LEVEL, false) do
      tag_size  = 300
      tag_ids   = Rails.cache.fetch("tags:random", :expires_in => CacheExpire.tags) do
        Tag.find(:all, :limit => tag_size, :order => 'taggings_count desc', :select => 'id').collect(&:id)
      end
      # find tag object
      Tag.find(tag_ids[rand(tag_size)])
    end
  end

  # returns true if the search klass is indexable
  def indexable_klass?(klass)
    ['events', 'search'].include?(klass)
  end

  # return true if the search tag/query can be indexed by robots
  def indexable_query?(tag, query, objects)
    return true if !tag.blank? and !objects.blank?
    return true if query.to_s == 'anything' and !objects.blank?
    return false
  end
end