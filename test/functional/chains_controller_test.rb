require 'test/test_helper'
require 'test/factories'

class ChainsControllerTest < ActionController::TestCase
  
  # index route
  should_route  :get, '/chains', :controller => 'chains', :action => 'index'

  # chains in a country
  should_route  :get, '/chains/us/1', :controller => 'chains', :action => 'country', :country => 'us', :id => 1
  
  # chains in a state
  should_route  :get, '/chains/us/il/1', 
                :controller => 'chains', :action => 'state', :country => 'us', :state => 'il', :id => 1

  # chains in a city
  should_route  :get, '/chains/us/il/chicago/1',
                :controller => 'chains', :action => 'city', :country => 'us', :state => 'il', :city => 'chicago', :id => 1
end