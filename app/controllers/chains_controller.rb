class ChainsController < ApplicationController
  before_filter   :normalize_page_number, :only => [:city]
  before_filter   :init_areas, :only => [:country, :state, :city]

  # use the acts_as_friendly_param plugin filter to handle showing a unique friendly url for chain locations
  around_filter ActionController::FriendlyFilter.new

  # GET /chains
  def index
    self.class.benchmark("*** Benchmarking popular chains", APP_LOGGER_LEVEL, false) do
      @chains = Chain.order_by_company.paginate(:page => 1, :per_page => 250).sort_by(&:display_name)
    end

    self.class.benchmark("*** Benchmarking chain alphabet", APP_LOGGER_LEVEL, false) do
      @letters = Chain.alphabet
    end

    @country  = Country.default
    @title    = "Chain Store Locator"
    @h1       = "Popular Chain Stores"

    # enable robots
    @robots   = true

    # track event
    track_chain_ga_event(params[:controller], "Index")

    respond_to do |format|
      format.html
    end
  end

  # GET /chains/[a-z|0-9]
  def letter
    @letter = params[:letter]

    self.class.benchmark("*** Benchmarking chains with #{@letter}", APP_LOGGER_LEVEL, false) do
      @chains = Chain.starts_with(@letter).paginate(:page => 1, :per_page => 250).sort_by(&:display_name)
    end

    self.class.benchmark("*** Benchmarking chain alphabet", APP_LOGGER_LEVEL, false) do
      @letters = Chain.alphabet
    end

    @country  = Country.default
    @title    = (@letter.digit? ? "Digit '#{@letter}'" : "Letter '#{@letter.upcase}'") + " | Chain Store Locator"
    @h1       = "Chain Stores starting with '#{@letter.upcase}'"

    # enable robots
    @robots   = true

    # track event
    track_chain_ga_event(params[:controller], "Index By Letter")

    respond_to do |format|
      format.html { render(:action => 'index') }
    end
  end

  # GET /chains/us/433-jimmy-johns
  def country
    # @country initialized in before filter
    @chain    = Chain.find(params[:id])

    # self.class.benchmark("*** Benchmarking chain store locations by state using facets", APP_LOGGER_LEVEL, false) do
    #   # facet search by chain id to find locations by state
    #   @facets   = Location.facets(:with => {:chain_ids => @chain.id}, :facets => [:state_id], :group_clause => "@count desc")
    #   @states   = Search.load_from_facets(@facets, State)
    # end

    # self.class.benchmark("*** Benchmarking chain store states", APP_LOGGER_LEVEL, false) do
    #   @states = State.all(:joins => {:locations => :companies}, :conditions => {:companies => {:chain_id => @chain.id}, :locations => {:country_id => @country.id}}).uniq.sort_by{|o| o.name}
    # end

    self.class.benchmark("*** Benchmarking chain store states", APP_LOGGER_LEVEL, false) do
      @states = State.find(@chain.states.keys).sort_by{|o| o.name}
    end

    # chain location count
    @count  = @chain.companies_count

    @title  = "#{@chain.display_name} Store Locator"
    @h1     = "#{@chain.display_name} Store Locator"

    # enable robots
    @robots = true

    # track event
    track_chain_ga_event(params[:controller], @chain, @country)

    respond_to do |format|
      format.html
    end
  end

  # GET /chains/us/il/433-jimmy-johns
  def state
    # @country, @state initialized in before filter
    @chain    = Chain.find(params[:id])

    # self.class.benchmark("*** Benchmarking chain store locations by city and state using facets", APP_LOGGER_LEVEL, false) do
    #   # facet search by chain id and state id
    #   @facets   = Location.facets(:with => {:chain_ids => @chain.id, :state_id => @state.id}, :facets => [:city_id, :state_id], :group_clause => "@count desc")
    #   @cities   = Search.load_from_facets(@facets, City)
    #   # state location count
    #   @count    = @facets[:state_id][@state.id]
    # end

    # self.class.benchmark("*** Benchmarking #{@state.name.downcase} chain store cities", APP_LOGGER_LEVEL, false) do
    #   @cities = City.all(:joins => {:locations => :companies}, :conditions => {:companies => {:chain_id => @chain.id}, :locations => {:state_id => @state.id}}).uniq.sort_by{|o| o.name}
    # end

    self.class.benchmark("*** Benchmarking #{@state.name.downcase} chain store cities", APP_LOGGER_LEVEL, false) do
      city_ids  = @chain.states[@state.id] || []
      @cities   = City.find(city_ids).sort_by{|o| o.name}
    end

    @title = "#{@chain.display_name} Locations in #{@state.name} | Store Locator"
    @h1    = "#{@chain.display_name} Locations in #{@state.name}"

    # enable robots
    @robots = true

    # track event
    track_chain_ga_event(params[:controller], @chain, @state)

    respond_to do |format|
      format.html
    end
  end

  # GET /chains/us/il/chicago/433-jimmy-johns
  def city
    # @country, @state, @city initialized in before filter
    @chain      = Chain.find(params[:id])

    self.class.benchmark("*** Benchmarking chain store locations in #{@city.name.downcase} using sphinx", APP_LOGGER_LEVEL, false) do
      @eagers       = [:company, :state, :city, :zip, :primary_phone_number]
      @per_page     = 5
      @max_matches  = 200
      @locations    = Location.search(@chain.display_name,
                                      :with => {:chain_ids => @chain.id, :city_id => @city.id}, :include => @eagers,
                                      :page => params[:page], :per_page => @per_page, :max_matches => @max_matches)
      # the first reference to 'locations' does the actual sphinx query 
      logger.debug("*** [sphinx] locations: #{@locations.size}")
    end

    @title      = "#{@chain.display_name} Locations in #{@city.name}, #{@state.name} | Store Locator"
    @h1         = "#{@chain.display_name} Locations in #{@city.name}, #{@state.name}"

    # enable/disable robots
    @robots     = params[:page].to_i == 0 ? true : false

    # track event
    track_chain_ga_event(params[:controller], @chain, @city)

    respond_to do |format|
      format.html
    end
  end

  protected

  def init_areas
    @country = Country.find_by_code(params[:country].to_s.upcase)
    
    if @country.blank?
      redirect_to(:controller => 'places', :action => 'error', :locality => 'country') and return
    end
    
    case params[:action]
    when 'country'
      return true
    end

    # find the specified state for all other cases
    @state = @country.states.find_by_code(params[:state].to_s.upcase)

    if @state.blank?
      redirect_to(:controller => 'places', :action => 'error', :locality => 'state') and return
    end
    
    case params[:action]
    when 'state'
      return true
    when 'city'
      # find city
      @city = @state.cities.find_by_name(params[:city].to_s.titleize)
      
      if @city.blank?
        redirect_to(:controller => 'places', :action => 'error', :locality => 'city') and return
      end
    end
    
    return true
  end
  
end