class ChainsController < ApplicationController
  before_filter   :init_areas, :only => [:country, :state, :city]
  layout "home"

  def index
    @chains   = Chain.all(:order => "name ASC")
    @country  = Country.default
    
    @title    = "Chain Store Locator"
    @h1       = "Chain Stores"
  end

  def country
    # @country initialized in before filter
    @chain    = Chain.find(params[:name].to_i)
    @states   = @chain.states
    
    @title    = "#{@chain.name} Store Locator"
    @h1       = @title
  end
  
  def state
    # @country, @state initialized in before filter
    @chain      = Chain.find(params[:name].to_i)
    @locations  = @chain.locations.for_state(@state)
    @cities     = @locations.collect(&:city).uniq
    
    @title      = "#{@chain.name} Locations in #{@state.name}"
    @h1         = @title
  end
  
  def city
    # @country, @state initialized in before filter
    @chain      = Chain.find(params[:name].to_i)
    @locations  = @chain.locations.for_city(@city)
    
    @title      = "#{@chain.name} Locations in #{@city.name}, #{@state.name}"
    @h1         = @title
  end
  
  protected
  
  def init_areas
    @country = Country.find_by_code(params[:country].to_s.upcase)
    
    if @country.blank?
      redirect_to(:controller => 'places', :action => 'error', :area => 'country') and return
    end
    
    case params[:action]
    when 'country'
      return true
    end

    # find the specified state for all other cases
    @state = State.find_by_code(params[:state].to_s.upcase)

    if @state.blank?
      redirect_to(:controller => 'places', :action => 'error', :area => 'state') and return
    end
    
    case params[:action]
    when 'state'
      return true
    when 'city'
      # find city
      @city = @state.cities.find_by_name(params[:city].to_s.titleize)
      
      if @city.blank?
        redirect_to(:controller => 'places', :action => 'error', :area => 'city') and return
      end
    end
    
    return true
  end
  
end