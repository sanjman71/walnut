class ZipsController < ApplicationController
  before_filter   :init_areas, :only => [:country, :state, :city]
  layout "home"
  
  def country
    # @country, @states initialized in before filter
    @title  = "#{@country.name} Zip Code Finder"
  end
  
  def state
    # @country, @state, @zips and @cities initialized in before filter
    @title  = "#{@state.name} Zip Code Finder"
  end
  
  def index
    redirect_to(:action => 'country', :country => 'us') and return
  end
  
  protected
  
  def init_areas
    # country is required for all actions
    @country  = Country.find_by_code(params[:country].to_s.upcase)
    
    if @country.blank?
      redirect_to(:controller => 'zips', :action => 'error', :area => :country) and return
    end
    
    case params[:action]
    when 'country'
      # find all states
      @states = @country.states
      return true
    else
      # find the specified state for all other cases
      @state  = State.find_by_code(params[:state].to_s.upcase)
    end

    if @state.blank?
      redirect_to(:controller => 'zips', :action => 'error', :area => :state) and return
    end
    
    case params[:action]
    when 'state'
      # find all state cities and zips
      @cities = @state.cities
      @zips   = @state.zips
    end
    
    return true
  end
  
end