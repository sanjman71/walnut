ActionController::Routing::Routes.draw do |map|
  # The priority is based upon order of creation: first created -> highest priority.

  # user, session routes
  map.login       '/login',         :controller => 'sessions', :action => 'new', :conditions => {:method => :get}
  map.login       '/login',         :controller => 'sessions', :action => 'create', :conditions => {:method => :post}
  map.logout      '/logout',        :controller => 'sessions', :action => 'destroy'

  # rpx routes
  map.rpx_login   '/rpx/login',     :controller => 'rpx', :action => 'login'

  # unauthorized route
  map.unauthorized  '/unauthorized', :controller => 'home', :action => 'unauthorized'

  # locations routes
  map.connect     '/locations/:id/recommend', :controller => 'locations', :action => 'recommend', :conditions => {:method => :post}
  map.connect     '/locations/:city/random', :controller => 'locations', :action => 'random', :conditions => {:method => :get}

  map.resources   :locations, :only => [:index, :show, :create]

  # search error route
  map.connect     '/search/error/:locality', :controller => 'search', :action => 'error'
  
  # search
  map.connect     '/search/resolve', :controller => 'search', :action => 'resolve', :conditions => {:method => :post}
  map.connect     '/:klass/:country/:state/:city/n/:neighborhood/tag/:tag', :controller => 'search', :action => 'index', :neighborhood => /[a-z-]+/, 
                  :klass => /search|locations|events/
  map.connect     '/:klass/:country/:state/:city/n/:neighborhood/q/:query', :controller => 'search', :action => 'index', :neighborhood => /[a-z-]+/, 
                  :klass => /search|locations|events/
  map.connect     '/search/:country/:state/:city/n/:neighborhood', :controller => 'search', :action => 'neighborhood', :neighborhood => /[a-z-]+/
  map.connect     '/:klass/:country/:state/:city/tag/:tag', :controller => 'search', :action => 'index', :city => /[a-z-]+/, 
                  :klass => /search|locations|events/
  map.connect     '/:klass/:country/:state/:city/q/:query', :controller => 'search', :action => 'index', :city => /[a-z-]+/, 
                  :klass => /search|locations|events/
  map.connect     '/search/:country/:state/:city', :controller => 'search', :action => 'city', :city => /[a-z-]+/ # city must be lowercase
  map.connect     '/:klass/:country/:state/:zip/tag/:tag', :controller => 'search', :action => 'index', :zip => /\d{5}/, 
                  :klass => /search|locations|events/
  map.connect     '/:klass/:country/:state/:zip/q/:query', :controller => 'search', :action => 'index', :zip => /\d{5}/,
                  :klass => /search|locations|events/
  map.connect     '/search/:country/:state/:zip', :controller => 'search', :action => 'zip', :zip => /\d{5}/ # zip must be 5 digits
  map.connect     '/search/:country/:state', :controller => 'search', :action => 'state', :state => /[a-z]{2}/ # state must be 2 letters
  map.connect     '/search/:country', :controller => 'search', :action => 'country', :country => /[a-z]{2}/ # country must be 2 letters

  # autocomplete route
  map.search_where_complete          '/autocomplete/search/where', :controller => 'autocomplete', :action => 'where'
  map.search_where_complete_format   '/autocomplete/search/where.:format', :controller => 'autocomplete', :action => 'where'

  # chains routes
  map.chain_letter    '/chains/:letter', :controller => 'chains', :action => 'letter', :letter => /[a-z0-9]{1}/
  map.chain_country   '/chains/:country/:id', :controller => 'chains', :action => 'country'
  map.chain_state     '/chains/:country/:state/:id', :controller => 'chains', :action => 'state'
  map.chain_city      '/chains/:country/:state/:city/:id', :controller => 'chains', :action => 'city'
  
  map.resources   :chains, :only => [:index]

  
  # tag group routes
  map.resources   :taggs

  # tag routes
  map.resources   :tags

  # messages routes
  map.resources       :messages, :only => [:index, :create]
  map.new_email       '/messages/new/email', :controller => 'messages', :action => 'new_email'
  map.new_sms         '/messages/new/sms', :controller => 'messages', :action => 'new_sms'

  # event venue routes
  map.filtered_city_venues  '/venues/:country/:state/:city/:filter', :controller => 'event_venues', :action => 'city', :city => /[a-z-]+/,
                            :filter => /all|mapped|unmapped/
  map.city_venues           '/venues/:country/:state/:city', :controller => 'event_venues', :action => 'city', :city => /[a-z-]+/ 
  map.country_venues        '/venues/:country', :controller => 'event_venues', :action => 'country', :country => /[a-z]{2}/ 
  map.add_venue             '/venues/:id/add', :controller => 'event_venues', :action => 'add'
  map.resources             :event_venues, :only => [:create]
  
  # zip routes
  map.connect     '/zips/error/:locality', :controller => 'zips', :action => 'error'
  map.connect     '/zips/:country/:state/:city', :controller => 'zips', :action => 'city', :city => /[a-z-]+/
  map.connect     '/zips/:country/:state/:zip', :controller => 'zips', :action => 'zip', :zip => /\d{5}/
  map.connect     '/zips/:country/:state', :controller => 'zips', :action => 'state'
  map.connect     '/zips/:country', :controller => 'zips', :action => 'country', :country => /[a-z]{2}/ # country must be 2 letters

  map.resources   :zips, :only => [:index]
  
  # map the root to the home controller
  map.root        :controller => 'home', :action => 'index'
  
  map.about       '/about', :controller => 'home', :action => 'about'
  map.contactus   '/contactus', :controller => 'home', :action => 'contactus'
  
  map.stats_googlebot     '/bots/googlebot', :controller => 'log_stats', :action => 'googlebot'
  map.stats_googlemedia   '/bots/googlemedia', :controller => 'log_stats', :action => 'googlebot'

  # events controller
  map.new_event     '/locations/:location_id/events/new',       :controller => 'events', :action => 'new'
  map.create_event  '/locations/:location_id/events',           :controller => 'events', :action => 'create', :conditions => {:method => :post}
  map.show_event    '/locations/:location_id/event/:event_id',  :controller => 'events', :action => 'show'

  map.import_events     '/events/import/:city', :controller => 'events', :action => 'import'
  map.import_all_events '/events/import', :controller => 'events', :action => 'import'
  map.remove_events     '/events/remove', :controller => 'events', :action => 'remove'
  map.events            '/events', :controller => 'events', :action => 'index'

  # sitemaps controller
  map.sitemap_events    '/sitemap.events.xml', :controller => 'sitemaps', :action => 'events'
  map.sitemap_tags      '/sitemap.tags.:state.:city.xml', :controller => 'sitemaps', :action => 'tags', :state => /[a-z]{2}/, :city => /[a-z-]+/
  map.sitemap_chains    '/sitemap.chains.:id.xml', :controller => 'sitemaps', :action => 'chains'
  map.sitemap_locations '/sitemap.locations.:state.:city.:index.xml', :controller => 'sitemaps', :action => 'locations', :state => /[a-z]{2}/, :city => /[a-z-]+/, :index => /[0-9]+/
  map.sitemap_metro     '/sitemap.locations.cities.:city_size.:index.xml', :controller => 'sitemaps', :action => 'locations', :city_size => /tiny|small|medium/, :index => /[0-9]+/

  map.sitemap_ilocations  '/sitemap.index.locations.:state.:city.xml', :controller => 'sitemaps', :action => 'index_locations', :state => /[a-z]{2}/, :city => /[a-z-]+/
  map.sitemap_ilocations  '/sitemap.index.locations.cities.:city_size.xml', :controller => 'sitemaps', :action => 'index_locations', :city_size => /tiny|small|medium/
  map.sitemap_ichains     '/sitemap.index.chains.xml', :controller => 'sitemaps', :action => 'index_chains'

  # sphinx controller
  map.resources       :sphinx, :only => [:index]
  map.sphinx_reindex  '/sphinx/reindex/:index', :controller => 'sphinx', :action => 'reindex'

  # debug controller
  map.connect   '/debug/grid', :controller => 'debug', :action => 'toggle_blueprint_grid', :conditions => {:method => :put}

  # Sample of regular route:
  #   map.connect 'products/:id', :controller => 'catalog', :action => 'view'
  # Keep in mind you can assign values other than :controller and :action

  # Sample of named route:
  #   map.purchase 'products/:id/purchase', :controller => 'catalog', :action => 'purchase'
  # This route can be invoked with purchase_url(:id => product.id)

  # Sample resource route (maps HTTP verbs to controller actions automatically):
  #   map.resources :products

  # Sample resource route with options:
  #   map.resources :products, :member => { :short => :get, :toggle => :post }, :collection => { :sold => :get }

  # Sample resource route with sub-resources:
  #   map.resources :products, :has_many => [ :comments, :sales ], :has_one => :seller
  
  # Sample resource route with more complex sub-resources
  #   map.resources :products do |products|
  #     products.resources :comments
  #     products.resources :sales, :collection => { :recent => :get }
  #   end

  # Sample resource route within a namespace:
  #   map.namespace :admin do |admin|
  #     # Directs /admin/products/* to Admin::ProductsController (app/controllers/admin/products_controller.rb)
  #     admin.resources :products
  #   end

  # You can have the root of your site routed with map.root -- just remember to delete public/index.html.
  # map.root :controller => "welcome"

  # See how all your routes lay out with "rake routes"

  # Install the default routes as the lowest priority.
  # Note: These default routes make all actions in every controller accessible via GET requests. You should
  # consider removing the them or commenting them out if you're using named routes and resources.
  map.connect ':controller/:action/:id'
  map.connect ':controller/:action/:id.:format'
end
