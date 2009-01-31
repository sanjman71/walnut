class PlacesController < ApplicationController
  layout "home"
  
  def index
    @query      = params[:query]
     
    @places     = Address.search(@query)
  end
  
end
