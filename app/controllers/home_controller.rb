class HomeController < ApplicationController
  
  def index
    @country    = Country.default
    @states     = State.all
    @cities     = City.all
  end

end