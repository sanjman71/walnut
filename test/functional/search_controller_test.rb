require 'test/test_helper'
require 'test/factories'

class SearchControllerTest < ActionController::TestCase

  # city search tag route
  should_route :get, '/search/us/il/chicago/food',
               :controller => 'search', :action => 'index', :country => 'us', :state => 'il', :city => 'chicago', :what => 'food'

end