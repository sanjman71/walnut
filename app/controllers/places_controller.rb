class PlacesController < ApplicationController
  layout "home"
  
  def index
    @query      = params[:query]
     
    @addresses  = Address.search(@query)
  end
  
end
