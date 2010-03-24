class SpecialsController < ApplicationController
  before_filter   :normalize_page_number, :only => [:city_day]
  before_filter   :init_localities, :only => [:city, :city_day]
  before_filter   :init_weather, :only => [:city, :city_day]

  # GET /specials
  def index
    @country  = Country.us
    @state    = @country.states.find_by_name("Illinois")
    @city     = @state.cities.find_by_name("Chicago")
    redirect_to(specials_city_path(@country, @state, @city))
  end

  # GET /specials/us/il/chicago
  def city
    # @country, @state, @city all iniitialized in before_filter

    @today  = Time.zone.now
    @days   = Special.days

    @title  = [@city.name.titleize, 'Specials'].reject(&:blank?).join(' ')
    @h1     = @title

    track_special_ga_event(params[:controller], @city)
  end

  # GET /specials/us/il/chicago/weekly
  # GET /specials/us/il/chicago/monday
  def city_day
    # @country, @state, @city all iniitialized in before_filter

    @day    = params[:day].to_s
    
    # find tags that specials should be marked with
    @tags           = [Tag.find_by_name(Special.tag_name), Special.day?(@day) ? Tag.find_by_name(@day) : ''].reject(&:blank?)

    # build sphinx options
    @hash           = Search.query('special')
    @attributes     = Hash[:tag_ids => @tags.collect(&:id), :city_id => @city.id]
    @klasses        = [Appointment]
    @sort_order     = "@relevance desc"
    @eager_loads    = [{:location => :company}, :tags]
    @page           = params[:page] ? params[:page].to_i : 1
    @sphinx_options = Hash[:classes => @klasses, :with_all => @attributes, :match_mode => :extended2, :rank_mode => :bm25,
                           :order => @sort_order, :include => @eager_loads, :page => @page, :per_page => search_per_page,
                           :max_matches => search_max_matches]

    self.class.benchmark("*** Benchmarking sphinx query", APP_LOGGER_LEVEL, false) do
      @specials = ThinkingSphinx.search(@hash[:query_quorum], @sphinx_options)
      # the first reference to 'specials' invokes the sphinx query
      logger.debug("*** [sphinx] specials: #{@specials.size}")
    end

    # build special keywords from special preferences
    # e.g. if the special has a preference called special_drink, the keyword will be 'drink'
    @keywords = @specials.inject([]) do |array, special|
      hash = Special.preferences(special.preferences)
      hash.keys.each do |key|
        tagging = Special.preference_name(key)
        array.push(tagging) unless array.include?(tagging)
      end
      array
    end.sort

    @other_days = Special.days - [@day.titleize]

    @title      = [@city.name.titleize, @day.titleize, 'Specials'].reject(&:blank?).join(' ')
    @h1         = @title

    track_special_ga_event(params[:controller], @city, @day)
  end

  protected

  def search_max_matches
    100
  end

  def search_per_page
    mobile_device? ? 5 : 5
  end

  def search_max_page
    search_max_matches / search_per_page
  end
  
end