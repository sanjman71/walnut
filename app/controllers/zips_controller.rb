class ZipsController < ApplicationController
  # before_filter   :init_areas, :only => [:country, :state, :city, :zip]
  before_filter   :init_localities, :only => [:country, :state, :city, :zip]
  
  privilege_required 'manage site', :on => :current_user
  
  def country
    # @country, @states initialized in before filter
    
    # filter states with zips
    @states = @states.find_all { |o| o.zips_count > 0 }
    @title  = "#{@country.name} Zip Code Finder"
    @h1     = "Find Zips by State"
  end
  
  def state
    # @country, @state, @zips and @cities initialized in before filter
    
    @title  = "#{@state.name} Zip Code Finder"
    @h1     = "#{@state.name} Zip Code Directory"
  end
  
  def zip
    # @country, @state, @zip and @cities all initialized in before filter

    # find (and cache) nearby zips, where nearby is defined with a mile radius range
    nearby_miles    = 10
    nearby_limit    = 10
    @nearby_zips    = Zip.exclude(@zip).within_state(@state).all(:origin => @zip, :within => nearby_miles, :order => "distance ASC", :limit => nearby_limit)
    # @nearby_zips    = Rails.cache.fetch("#{@zip.name.parameterize}:nearby:zips", :expires_in => CacheExpire.localities) do
    #   Zip.exclude(@zip).within_state(@state).all(:origin => @zip, :within => nearby_miles, :order => "distance ASC", :limit => nearby_limit)
    # end
    
    @title  = "#{@zip.name} #{@state.code} Zip Code"
    @h1     = "#{@zip.name} #{@state.code} Zip Code"
  end
  
  def index
    redirect_to(:action => 'country', :country => 'us') and return
  end
  
  protected
  
  # def init_areas
  #   # country is required for all actions
  #   @country  = Country.find_by_code(params[:country].to_s.upcase)
  #   
  #   if @country.blank?
  #     redirect_to(:controller => 'zips', :action => 'error', :locality => :country) and return
  #   end
  #   
  #   case params[:action]
  #   when 'country'
  #     # find all states
  #     @states = @country.states
  #     return true
  #   else
  #     # find the specified state for all other cases
  #     @state  = State.find_by_code(params[:state].to_s.upcase)
  #   end
  # 
  #   if @state.blank?
  #     redirect_to(:controller => 'zips', :action => 'error', :locality => :state) and return
  #   end
  #   
  #   case params[:action]
  #   when 'state'
  #     # find all state cities and zips
  #     @cities = @state.cities
  #     @zips   = @state.zips
  #   end
  #   
  #   return true
  # end
  
end