require 'test/test_helper'

class SitemapsControllerTest < ActionController::TestCase
  
  should_route :get, '/sitemap_city_events', :controller => 'sitemaps', :action => 'events'
  should_route :get, '/sitemap_city_tags', :controller => 'sitemaps', :action => 'tags'

end