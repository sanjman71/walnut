class HomeController < ApplicationController
  def index
    @country        = Country.default
    @states         = State.all
    @cities         = City.with_locations.order_by_density.all(:limit => 30)
    @neighborhoods  = Neighborhood.with_locations.order_by_density.all(:limit => 10, :include => :city)

    respond_to do |format|
      format.html
    end
  end

  # Handle all unauthorized access redirects
  def unauthorized
    respond_to do |format|
      format.html
    end
  end

end