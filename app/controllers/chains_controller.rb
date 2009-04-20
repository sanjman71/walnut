class ChainsController < ApplicationController
  before_filter   :init_areas, :only => [:country, :state, :city]

  def index
    @chains   = Chain.places.all(:order => "name ASC")
    @country  = Country.default
    
    @title    = "Chain Store Locator"
    @h1       = "Chain Stores"
  end

  def country
    # @country initialized in before filter
    @chain    = Chain.find(params[:name].to_i)

    # facet search by chain id
    @facets   = Location.facets(:conditions => {:chain_id => @chain.id})
    @states   = State.find(@facets[:state_id].keys)
    # count locations in country
    @count    = @facets[:country_id].values.first.to_i

    @title    = "#{@chain.name} Store Locator"
  end
  
  def state
    # @country, @state initialized in before filter
    @chain      = Chain.find(params[:name].to_i)
    
    # facet search by chain id and state id
    @facets   = Location.facets(:conditions => {:chain_id => @chain.id, :state_id => @state.id})
    @cities   = City.find(@facets[:city_id].keys)
    # count locations in state
    @count    = @facets[:state_id][@state.id]

    @title      = "#{@chain.name} Locations in #{@state.name}"
  end
  
  def city
    # @country, @state, @city initialized in before filter
    @chain      = Chain.find(params[:name].to_i)
    @locations  = @chain.locations.for_city(@city)

    # facet search by chain id and city id
    @facets   = Location.facets(:conditions => {:chain_id => @chain.id, :city_id => @city.id})

    @title      = "#{@chain.name} Locations in #{@city.name}, #{@state.name}"
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
    @state = State.find_by_code(params[:state].to_s.upcase)

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