require 'test/test_helper'
require 'test/factories'

class EventsControllerTest < ActionController::TestCase
  
  # country route
  should_route :get, '/events/us', :controller => 'events', :action => 'country', :country => 'us'
  
  # state route
  should_route :get, '/events/us/il',
               :controller => 'events', :action => 'state', :country => 'us', :state => 'il'

  # city route
  should_route :get, '/events/us/il/chicago', :controller => 'events', :action => 'city', :country => 'us', :state => 'il', :city => 'chicago'
  # city tag route
  should_route :get, '/events/us/il/chicago/festivals',
               :controller => 'events', :action => 'index', :country => 'us', :state => 'il', :city => 'chicago', :what => 'festivals'

  # city category route
  should_route :get, '/events/us/il/chicago/c/music',
               :controller => 'events', :action => 'index', :country => 'us', :state => 'il', :city => 'chicago', :category => 'music'
               
  # city popular route
  should_route :get, '/events/us/il/chicago/popular',
               :controller => 'events', :action => 'index', :country => 'us', :state => 'il', :city => 'chicago', :filter => 'popular'
end