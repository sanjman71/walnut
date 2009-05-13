require 'test/test_helper'
require 'test/factories'

class EventVenuesControllerTest < ActionController::TestCase
  
  # country route
  should_route :get, '/venues/us', :controller => 'event_venues', :action => 'country', :country => 'us'
  
  # city route
  should_route :get, '/venues/us/il/chicago', :controller => 'event_venues', :action => 'city', :country => 'us', :state => 'il', :city => 'chicago'
  
  # add event venue as a place
  should_route :get, '/venues/1/add', :controller => 'event_venues', :action => 'add', :id => 1
end