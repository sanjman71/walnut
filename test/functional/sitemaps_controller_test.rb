require 'test/test_helper'

class SitemapsControllerTest < ActionController::TestCase

  should_route :get, '/sitemap.events.xml', :controller => 'sitemaps', :action => 'events'
  should_route :get, '/sitemap.tags.il.chicago.xml', :controller => 'sitemaps', :action => 'tags', :city => 'chicago', :state => 'il'
  should_route :get, '/sitemap.locations.il.chicago.1.xml', :controller => 'sitemaps', :action => 'locations', :state => 'il', :city => 'chicago', :index => '1'

end