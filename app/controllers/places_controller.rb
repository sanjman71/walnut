class PlacesController < ApplicationController
  layout "home"
    
  def index
    @country    = Country.find_by_code(params[:country].to_s.upcase)
    @state      = State.find_by_code(params[:state].to_s.upcase)
    @city       = City.find_by_name(params[:city].to_s.titleize)
    @tag        = params[:tag]
    
    # if @country.blank?
    #   @country = Country.default
    #   logger.debug("*** redirecting to default country")
    #   redirect_to(url_for(:country => @country, :query => @query)) and return
    # end
    
    # build sphinx query
    @query      = [@country, @state, @city, @tag].compact.collect { |o| o.is_a?(String) ? o : o.name }.join(" ")
    
    # find addresses matching query
    @addresses  = Address.search(@query)
  end
  
end
