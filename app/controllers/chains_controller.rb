class ChainsController < ApplicationController
  before_filter   :init_areas, :only => [:country, :state, :city]

  def index
    @chains   = Chain.places.all(:order => "name ASC")
    @country  = Country.default
    
    @title    = "Chain Store Locator"
    @h1       = "Chain Stores"

    # track event
    track_chain_ga_event(params[:controller], "Index")
  end

  def country
    # @country initialized in before filter
    @chain    = Chain.find(params[:name].to_i)

    # facet search by chain id
    @facets   = Location.facets(:conditions => {:chain_ids => @chain.id}, :facets => ["country_id", "state_id"])
    @states   = Search.load_from_facets(@facets, State)
    # count locations in country
    @count    = @facets[:country_id][@country.id]

    @title    = "#{@chain.name} Store Locator"
    
    # track event
    track_chain_ga_event(params[:controller], @chain, @country)
  end
  
  def state
    # @country, @state initialized in before filter
    @chain      = Chain.find(params[:name].to_i)
    
    # facet search by chain id and state id
    @facets   = Location.facets(:conditions => {:chain_ids => @chain.id, :state_id => @state.id}, :facets => ["city_id", "state_id"])
    @cities   = Search.load_from_facets(@facets, City)
    # count locations in state
    @count    = @facets[:state_id][@state.id]

    @title    = "#{@chain.name} Locations in #{@state.name}"

    # track event
    track_chain_ga_event(params[:controller], @chain, @state)
  end
  
  def city
    # @country, @state, @city initialized in before filter
    @chain      = Chain.find(params[:name].to_i)
    @locations  = Location.search(:conditions => {:chain_ids => @chain.id, :city_id => @city.id}, :include => [:state, :city, :zip])

    @title      = "#{@chain.name} Locations in #{@city.name}, #{@state.name}"

    # track event
    track_chain_ga_event(params[:controller], @chain, @city)
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