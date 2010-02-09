require 'test/test_helper'

class SitemapsControllerTest < ActionController::TestCase

  # events
  should_route :get, '/sitemap.events.xml', :controller => 'sitemaps', :action => 'events'

  # tags
  should_route :get, '/sitemap.tags.il.chicago.xml', :controller => 'sitemaps', :action => 'tags', :city => 'chicago', :state => 'il'

  # locations
  should_route :get, '/sitemap.locations.il.chicago.1.xml', :controller => 'sitemaps', :action => 'locations', :state => 'il', :city => 'chicago', :index => '1'
  should_route :get, '/sitemap.locations.il.chicago.10.xml', :controller => 'sitemaps', :action => 'locations', :state => 'il', :city => 'chicago', :index => '10'
  should_route :get, '/sitemap.locations.cities.medium.1.xml', :controller => 'sitemaps', :action => 'locations', :city_size => 'medium', :index => '1'
  should_route :get, '/sitemap.locations.cities.small.1.xml', :controller => 'sitemaps', :action => 'locations', :city_size => 'small', :index => '1'
  should_route :get, '/sitemap.locations.cities.tiny.1.xml', :controller => 'sitemaps', :action => 'locations', :city_size => 'tiny', :index => '1'
  should_route :get, '/sitemap.index.locations.il.chicago.xml', :controller => 'sitemaps', :action => 'index_locations', :state => 'il', :city => 'chicago'
  should_route :get, '/sitemap.index.locations.cities.medium.xml', :controller => 'sitemaps', :action => 'index_locations', :city_size => 'medium'

  # chains
  should_route :get, '/sitemap.chains.1.xml', :controller => 'sitemaps', :action => 'chains', :id => '1'
  should_route :get, '/sitemap.index.chains.xml', :controller => 'sitemaps', :action => 'index_chains'

  # zips
  should_route :get, '/sitemap.index.zips.xml', :controller => 'sitemaps', :action => 'index_zips'
  should_route :get, '/sitemap.zips.il.xml', :controller => 'sitemaps', :action => 'zips', :state => 'il'

end