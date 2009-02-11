class HomeController < ApplicationController
  
  def index
    @country    = Country.default
    @states     = State.all
    @cities     = City.all
    @tags       = Location.place_tag_counts.collect(&:name)
  end

end