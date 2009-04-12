class HomeController < ApplicationController
  
  def index
    @country        = Country.default
    @states         = State.all
    @cities         = City.order_by_density.all(:limit => 30)
    @neighborhoods  = Neighborhood.order_by_density(:limit => 10)
  end

end