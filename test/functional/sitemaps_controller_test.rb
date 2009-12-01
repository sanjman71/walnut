require 'test/test_helper'

class SitemapsControllerTest < ActionController::TestCase

  should_route :get, '/sitemap.events', :controller => 'sitemaps', :action => 'events'
  should_route :get, '/sitemap.tags.chicago', :controller => 'sitemaps', :action => 'tags', :city => 'chicago'

end