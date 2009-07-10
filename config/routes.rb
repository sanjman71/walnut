ActionController::Routing::Routes.draw do |map|
  # The priority is based upon order of creation: first created -> highest priority.

  # user, session routes
  map.login       '/login',         :controller => 'sessions', :action => 'new', :conditions => {:method => :get}
  map.login       '/login',         :controller => 'sessions', :action => 'create', :conditions => {:method => :post}
  map.logout      '/logout',        :controller => 'sessions', :action => 'destroy'

  # unauthorized route
  map.unauthorized  '/unauthorized', :controller => 'home', :action => 'unauthorized'

  # locations routes
  map.connect     '/locations/:id/recommend', :controller => 'locations', :action => 'recommend', :conditions => {:method => :post}
  map.connect     '/locations/:city/random', :controller => 'locations', :action => 'random', :conditions => {:method => :get}

  map.resources   :locations, :only => [:index, :show, :create]

  # chains routes
  map.connect     '/chains/:country/:id', :controller => 'chains', :action => 'country'
  map.connect     '/chains/:country/:state/:id', :controller => 'chains', :action => 'state'
  map.connect     '/chains/:country/:state/:city/:id', :controller => 'chains', :action => 'city'
  
  map.resources   :chains, :only => [:index]

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
  map.connect     '/autocomplete/search/where', :controller => 'autocomplete', :action => 'where'
  
  # tag group routes
  map.resources   :taggs

  # tag routes
  map.resources   :tags
  
  # event venue routes
  map.filtered_city_venues  '/venues/:country/:state/:city/:filter', :controller => 'event_venues', :action => 'city', :city => /[a-z-]+/,
                            :filter => /all|mapped|unmapped/
  map.city_venues           '/venues/:country/:state/:city', :controller => 'event_venues', :action => 'city', :city => /[a-z-]+/ 
  map.country_venues        '/venues/:country', :controller => 'event_venues', :action => 'country', :country => /[a-z]{2}/ 
  map.add_venue             '/venues/:id/add', :controller => 'event_venues', :action => 'add'
  map.resources             :event_venues, :only => [:create]
  
  # zip routes
  map.connect     '/zips/error/:locality', :controller => 'zips', :action => 'error'
  map.connect     '/zips/:country/:state/:city', :controller => 'zips', :action => 'city'
  map.connect     '/zips/:country/:state', :controller => 'zips', :action => 'state'
  map.connect     '/zips/:country', :controller => 'zips', :action => 'country', :country => /[a-z]{2}/ # country must be 2 letters

  map.resources   :zips, :only => [:index]
  
  # map the root to the home controller
  map.root        :controller => 'home', :action => 'index'
  
  map.about       '/about', :controller => 'home', :action => 'about'
  map.contactus   '/contactus', :controller => 'home', :action => 'contactus'
  
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
