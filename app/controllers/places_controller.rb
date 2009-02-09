class PlacesController < ApplicationController
  layout "home"
  
  def country
    @country        = Country.find_by_code(params[:country].to_s.upcase)
    @states         = @country.states if @country
    
    @title          = "#{@country.name} Yellow Pages"
  end
      
  def state
    @country        = Country.find_by_code(params[:country].to_s.upcase)
    @state          = State.find_by_code(params[:state].to_s.upcase)
    @cities         = @state.cities if @state
    @zips           = @state.zips if @state
    
    @title          = "#{@state.name} Yellow Pages"
  end
  
  def city
    @country        = Country.find_by_code(params[:country].to_s.upcase)
    @state          = State.find_by_code(params[:state].to_s.upcase)
    @city           = @state.cities.find_by_name(params[:city].to_s.titleize) unless @state.blank?
    @zips           = @city.zips
    @neighborhoods  = @city.neighborhoods
    @tags           = Address.place_tag_counts.sort_by(&:name)

    @title          = "#{@city.name}, #{@state.name} Yellow Pages"
  end

  def neighborhood
    @country        = Country.find_by_code(params[:country].to_s.upcase)
    @state          = State.find_by_code(params[:state].to_s.upcase)
    @city           = @state.cities.find_by_name(params[:city].to_s.titleize) unless @state.blank?
    @neighborhood   = @city.neighborhoods.find_by_name(params[:neighborhood].to_s.titleize) unless @city.blank?
    @tags           = Address.place_tag_counts.sort_by(&:name)

    @title          = "#{@neighborhood.name}, #{@city.name}, #{@state.name} Yellow Pages"
  end
  
  def zip
    @country        = Country.find_by_code(params[:country].to_s.upcase)
    @state          = State.find_by_code(params[:state].to_s.upcase)
    @zip            = @state.zips.find_by_name(params[:zip].to_s) unless @state.blank?
    @cities         = @zip.cities
    @tags           = Address.place_tag_counts.sort_by(&:name)

    @title          = "#{@state.name} #{@zip.name} Yellow Pages"
  end
  
  def index
    @country        = Country.find_by_code(params[:country].to_s.upcase)
    @state          = State.find_by_code(params[:state].to_s.upcase)
    @city           = @state.cities.find_by_name(params[:city].to_s.titleize) unless @state.blank?
    @zip            = @state.zips.find_by_name(params[:zip].to_s) unless @state.blank?
    @neighborhood   = @city.neighborhoods.find_by_name(params[:neighborhood].to_s.titleize) unless @city.blank?
    @tag            = params[:tag]
    
    # if @country.blank?
    #   @country = Country.default
    #   logger.debug("*** redirecting to default country")
    #   redirect_to(url_for(:country => @country, :query => @query)) and return
    # end
    
    # build sphinx query
    @query          = [@country, @state, @city, @neighborhood, @zip, @tag].compact.collect { |o| o.is_a?(String) ? o : o.name }.join(" ")

    # build search title based on city, neighborhood, zip search
    @title          = build_search_title(:tag => @tag, :city => @city, :neighborhood => @neighborhood, :zip => @zip, :state => @state)
    
    # find addresses matching query
    @addresses      = Address.search(@query).paginate(:page => params[:page])
  end
  
  protected
  
  def build_search_title(options={})
    tag = options[:tag] || ''
    
    if options[:state] and options[:city] and options[:neighborhood]
      where = "#{options[:neighborhood].name}, #{options[:city].name}, #{options[:state].name}"
    elsif options[:state] and options[:city]
      where = "#{options[:city].name}, #{options[:state].name}"
    elsif options[:state] and options[:zip]
      where = "#{options[:state].name}, #{options[:zip].name}"
    else
      raise Exception, "invalid search"
    end
    
    "#{tag.titleize} in #{where}"
  end
  
end
