require 'test/test_helper'
require 'test/factories'

class ChainsControllerTest < ActionController::TestCase
  
  # index route
  should_route  :get, '/chains', :controller => 'chains', :action => 'index'

  # chains in a country
  should_route  :get, '/chains/1/us', :controller => 'chains', :action => 'country', :name => 1, :country => 'us'
  
  # chains in a state
  should_route  :get, '/chains/1/us/il', 
                :controller => 'chains', :action => 'state', :name => 1, :country => 'us', :state => 'il'

  # chains in a city
  should_route  :get, '/chains/1/us/il/chicago',
                :controller => 'chains', :action => 'city', :name => 1, :country => 'us', :state => 'il', :city => 'chicago'
end