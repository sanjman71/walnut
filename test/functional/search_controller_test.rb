require 'test/test_helper'
require 'test/factories'

class SearchControllerTest < ActionController::TestCase

  # search resolve route
  should_route :post, '/search/resolve', :controller => 'search', :action => 'resolve'
  
  # state route
  should_route :get, '/search/us/il', :controller => 'search', :action => 'state', :country => 'us', :state => 'il'
  
  # city route
  should_route :get, '/search/us/il/chicago', :controller => 'search', :action => 'city', :country => 'us', :state => 'il', :city => 'chicago'
  
  # city search tag/what routes
  should_route :get, '/search/us/il/chicago/food',
               :controller => 'search', :action => 'index', :country => 'us', :state => 'il', :city => 'chicago', :what => 'food', :klass => 'search'
  should_route :get, '/search/us/il/chicago/tag/food',
               :controller => 'search', :action => 'index', :country => 'us', :state => 'il', :city => 'chicago', :tag => 'food', :klass => 'search'
  should_route :get, '/locations/us/il/chicago/food',
               :controller => 'search', :action => 'index', :country => 'us', :state => 'il', :city => 'chicago', :what => 'food', :klass => 'locations'
  should_route :get, '/locations/us/il/chicago/tag/food',
               :controller => 'search', :action => 'index', :country => 'us', :state => 'il', :city => 'chicago', :tag => 'food', :klass => 'locations'
  should_route :get, '/events/us/il/chicago/food',
               :controller => 'search', :action => 'index', :country => 'us', :state => 'il', :city => 'chicago', :what => 'food', :klass => 'events'
  should_route :get, '/events/us/il/chicago/tag/food',
               :controller => 'search', :action => 'index', :country => 'us', :state => 'il', :city => 'chicago', :tag => 'food', :klass => 'events'

  # neighborhood search tag/waht routes
  should_route :get, '/search/us/il/chicago/n/river-north/soccer',
               :controller => 'search', :action => 'index', :country => 'us', :state => 'il', :city => 'chicago', :neighborhood => 'river-north', 
               :what => 'soccer', :klass => 'search'
  should_route :get, '/search/us/il/chicago/n/river-north/tag/soccer', 
               :controller => 'search', :action => 'index', :country => 'us', :state => 'il', :city => 'chicago', :neighborhood => 'river-north', 
               :tag => 'soccer', :klass => 'search'
  should_route :get, '/locations/us/il/chicago/n/river-north/soccer',
               :controller => 'search', :action => 'index', :country => 'us', :state => 'il', :city => 'chicago', :neighborhood => 'river-north', 
               :what => 'soccer', :klass => 'locations'
  should_route :get, '/locations/us/il/chicago/n/river-north/tag/soccer',
               :controller => 'search', :action => 'index', :country => 'us', :state => 'il', :city => 'chicago', :neighborhood => 'river-north', 
               :tag => 'soccer', :klass => 'locations'
  should_route :get, '/events/us/il/chicago/n/river-north/soccer',
               :controller => 'search', :action => 'index', :country => 'us', :state => 'il', :city => 'chicago', :neighborhood => 'river-north', 
               :what => 'soccer', :klass => 'events'
  should_route :get, '/events/us/il/chicago/n/river-north/tag/soccer',
               :controller => 'search', :action => 'index', :country => 'us', :state => 'il', :city => 'chicago', :neighborhood => 'river-north', 
               :tag => 'soccer', :klass => 'events'

  # zip search tag/what routes
  should_route :get, '/search/us/il/60610/food',
               :controller => 'search', :action => 'index', :country => 'us', :state => 'il', :zip => '60610', :what => 'food', :klass => 'search'
  should_route :get, '/search/us/il/60610/tag/food',
               :controller => 'search', :action => 'index', :country => 'us', :state => 'il', :zip => '60610', :tag => 'food', :klass => 'search'
  should_route :get, '/locations/us/il/60610/food',
               :controller => 'search', :action => 'index', :country => 'us', :state => 'il', :zip => '60610', :what => 'food', :klass => 'locations'
  should_route :get, '/locations/us/il/60610/tag/food',
               :controller => 'search', :action => 'index', :country => 'us', :state => 'il', :zip => '60610', :tag => 'food', :klass => 'locations'
  should_route :get, '/events/us/il/60610/food',
               :controller => 'search', :action => 'index', :country => 'us', :state => 'il', :zip => '60610', :what => 'food', :klass => 'events'
  should_route :get, '/events/us/il/60610/tag/food',
               :controller => 'search', :action => 'index', :country => 'us', :state => 'il', :zip => '60610', :tag => 'food', :klass => 'events'


  # error route
  should_route :get, '/search/error/country', :controller => 'search', :action => 'error', :locality => 'country'
  should_route :get, '/search/error/unknown', :controller => 'search', :action => 'error', :locality => 'unknown'

end