class MenusController < ApplicationController
  before_filter   :normalize_page_number, :only => [:index]
  before_filter   :init_localities, :only => [:index]
  before_filter   :init_weather, :only => [:index]

  # GET /menus
  def country
    @country        = Country.us

    @hash           = Search.query('menu')
    @menu_tag       = Tag.find_by_name(Menu.tag_name)
    @attributes     = Hash[:tag_ids => @menu_tag.id]

    self.class.benchmark("*** Benchmarking menu cities using sphinx facets", APP_LOGGER_LEVEL, false) do
      # build menu city facets
      limit       = 1
      facets      = Location.facets(@hash[:query_quorum], :with_all => @attributes, :facets => [:city_id], :group_clause => "@count desc", 
                                    :limit => limit, :match_mode => :extended2)
      @cities     = Search.load_from_facets(facets, City)
      logger.debug("[sphinx] facet cities: #{@cities.inspect}")
    end

    @title    = "Restaurant Menus"
    @h1       = @title
  end

  # GET /menus/us/il/chicago
  def index
    # @country, @state, @city, @neighborhood all iniitialized in before_filter

    # find tags that menus should be marked with
    @tag            = Tag.find_by_name(params[:tag].to_s.from_url_param)
    @menu_tag       = Tag.find_by_name(Menu.tag_name)
    @search_tags    = [@menu_tag, @tag].compact
    @exclude_tags   = (@search_tags + ['restaurant', 'restaurants'].collect{|s| Tag.find_by_name(s)}).compact.collect(&:name).sort

    # build sphinx options
    @hash           = Search.query('menu')
    @attributes     = Hash[:tag_ids => @search_tags.collect(&:id), :city_id => @city.id, :neighborhood_ids => @neighborhood.andand.id]
    @klasses        = [Location]
    @sort_order     = "@relevance desc"
    @eager_loads    = [{:company => :tags}, :city, :state, :zip, :primary_phone_number]
    @page           = params[:page] ? params[:page].to_i : 1
    @sphinx_options = Hash[:classes => @klasses, :with_all => @attributes, :match_mode => :extended2, :rank_mode => :bm25,
                           :order => @sort_order, :include => @eager_loads, :page => @page, :per_page => search_per_page,
                           :max_matches => search_max_matches]

    self.class.benchmark("*** Benchmarking sphinx query", APP_LOGGER_LEVEL, false) do
      @locations = ThinkingSphinx.search(@hash[:query_quorum], @sphinx_options)
      # the first reference invokes the sphinx query
      logger.debug("*** [sphinx] menus: #{@locations.size}")
    end

    self.class.benchmark("*** Benchmarking #{@city.name.downcase} neighborhoods from database", APP_LOGGER_LEVEL, false) do
      unless @city.neighborhoods_count == 0
        @neighborhoods = @locations.collect(&:neighborhoods).flatten.uniq
      end
    end

    if !@neighborhood.blank?
      @nearby_cities = [@city]
    end

    @title  = build_search_title(:klass => 'menu', :tag => [@tag.andand.name, 'menus'].uniq.reject(&:blank?).join(' '), :query => nil, :city => @city, :neighborhood => @neighborhood, :state => @state)
    @h1     = build_search_h1(@tag.andand.name, Hash["city" => @city.name, "neighborhood" => @neighborhood.andand.name])

    # track_menu_ga_event(params[:controller], @city, @tag)
  end

  protected

  # build h1 tag from what (e.g. 'pizza'), and where (e.g. {"city" => 'Chicago', "neighborhood" => 'River North'})
  def build_search_h1(what, where)
    # e.g. "Pizza Restaurants"
    s1 = [what, 'restaurants'].uniq.reject(&:blank?).map(&:titleize)

    case where.keys.sort
    when ["city", "neighborhood"]
      s2 = [where["neighborhood"], where["city"]]
    when ["city"]
      s2 = [where["city"]]
    else
      s2 = []
    end

    "#{s1.join(" ")} in #{s2.reject(&:blank?).join(", ")}"
  end

  def search_max_matches
    100
  end

  def search_per_page
    mobile_device? ? 5 : 10
  end

  def search_max_page
    search_max_matches / search_per_page
  end

end