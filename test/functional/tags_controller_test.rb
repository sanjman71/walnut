require 'test/test_helper'

class TagsControllerTest < ActionController::TestCase
  
  # index route
  should_route :get, '/tags', :controller => 'tags', :action => 'index'

end