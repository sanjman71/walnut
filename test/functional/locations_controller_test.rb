require 'test/test_helper'
require 'test/factories'

class LocationsControllerTest < ActionController::TestCase
  
  should_route :post, '/locations/1/recommend', :controller => 'locations', :action => 'recommend', :id => '1'

end