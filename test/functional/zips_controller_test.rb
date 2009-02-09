require 'test/test_helper'
require 'test/factories'

class ZipsControllerTest < ActionController::TestCase
  
  def setup
    @us       = Factory(:us)
    @il       = Factory(:state, :name => "Illinois", :code => "IL", :country => @us)
  end

  # zip routes
  should_route :get, '/zips/us', :controller => 'zips', :action => 'country', :country => 'us'
  should_route :get, '/zips/us/il', :controller => 'zips', :action => 'state', :country => 'us', :state => 'il'
  should_route :get, '/zips/us/il/chicago', :controller => 'zips', :action => 'city', :country => 'us', :state => 'il', :city => 'chicago'
    
end