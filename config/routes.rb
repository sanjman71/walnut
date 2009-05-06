ActionController::Routing::Routes.draw do |map|
  # The priority is based upon order of creation: first created -> highest priority.

  # user, session routes
  map.login       '/login',         :controller => 'sessions', :action => 'new', :conditions => {:method => :get}
  map.login       '/login',         :controller => 'sessions', :action => 'create', :conditions => {:method => :post}
  map.logout      '/logout',        :controller => 'sessions', :action => 'destroy'

  # unauthorized route
  map.unauthorized  '/unauthorized', :controller => 'home', :action => 'unauthorized'

  # places error route
  map.connect     '/places/error/:locality', :controller => 'places', :action => 'error'
  
  # places [locality, tag] routes
  map.connect     '/places/:country/:state/:city/n/:neighborhood/tag/:tag', :controller => 'places', :action => 'index', :neighborhood => /[a-z-]+/
  map.connect     '/places/:country/:state/:city/n/:neighborhood/:what', :controller => 'places', :action => 'index', :neighborhood => /[a-z-]+/
  map.connect     '/places/:country/:state/:city/n/:neighborhood', :controller => 'places', :action => 'neighborhood', :neighborhood => /[a-z-]+/
  map.connect     '/places/:country/:state/:city/:filter', :controller => 'places', :action => 'index', :city => /[a-z-]+/, :filter => /recommended/
  map.connect     '/places/:country/:state/:city/tag/:tag', :controller => 'places', :action => 'index', :city => /[a-z-]+/
  map.connect     '/places/:country/:state/:city/:what', :controller => 'places', :action => 'index', :city => /[a-z-]+/
  map.connect     '/places/:country/:state/:city', :controller => 'places', :action => 'city', :city => /[a-z-]+/ # city must be lowercase
  map.connect     '/places/:country/:state/:zip/tag/:tag', :controller => 'places', :action => 'index', :zip => /\d{5}/ # zip must be 5 digits
  map.connect     '/places/:country/:state/:zip/:what', :controller => 'places', :action => 'index', :zip => /\d{5}/ # zip must be 5 digits
  map.connect     '/places/:country/:state/:zip', :controller => 'places', :action => 'zip', :zip => /\d{5}/
  map.connect     '/places/:country/:state', :controller => 'places', :action => 'state'
  map.connect     '/places/:country', :controller => 'places', :action => 'country', :country => /[a-z]{2}/ # country must be 2 letters
  
  map.resources   :places, :only => [:index, :show]
  
  # locations routes
  map.connect     '/locations/:id/recommend', :controller => 'locations', :action => 'recommend', :conditions => {:method => :post}

  # chains routes
  map.connect     '/chains/:name/:country', :controller => 'chains', :action => 'country'
  map.connect     '/chains/:name/:country/:state', :controller => 'chains', :action => 'state'
  map.connect     '/chains/:name/:country/:state/:city', :controller => 'chains', :action => 'city'
  
  map.resources   :chains, :only => [:index]
  
  # events [locality, tag, category] routes
  map.connect     '/events/:country/:state/:city/n/:neighborhood/:what', :controller => 'events', :action => 'index', :neighborhood => /[a-z-]+/
  map.connect     '/events/:country/:state/:city/n/:neighborhood', :controller => 'events', :action => 'neighborhood', :neighborhood => /[a-z-]+/
  map.connect     '/events/:country/:state/:city/search', :controller => 'events', :action => 'search', :city => /[a-z-]+/
  map.connect     '/events/:country/:state/:city/tag/:tag', :controller => 'events', :action => 'index', :city => /[a-z-]+/
  map.connect     '/events/:country/:state/:city/filter/:filter', :controller => 'events', :action => 'index', :city => /[a-z-]+/, :filter => /popular/
  map.connect     '/events/:country/:state/:city/category/:category', :controller => 'events', :action => 'index', :city => /[a-z-]+/
  map.connect     '/events/:country/:state/:city/:what', :controller => 'events', :action => 'index', :city => /[a-z-]+/ # city must be lowercase
  map.connect     '/events/:country/:state/:city', :controller => 'events', :action => 'city', :city => /[a-z-]+/
  map.connect     '/events/:country/:state/:zip/:what', :controller => 'events', :action => 'index', :zip => /\d{5}/ # zip must be 5 digits
  map.connect     '/events/:country/:state/:zip', :controller => 'events', :action => 'zip', :zip => /\d{5}/
  map.connect     '/events/:country/:state', :controller => 'events', :action => 'state'
  map.connect     '/events/:country', :controller => 'events', :action => 'country', :country => /[a-z]{2}/ # country must be 2 letters

  # search error route
  map.connect     '/search/error/:locality', :controller => 'search', :action => 'error'
  
  # search
  map.connect     '/search/resolve', :controller => 'search', :action => 'resolve', :conditions => {:method => :post}
  map.connect     '/search/:country/:state/:city/n/:neighborhood/tag/:tag', :controller => 'search', :action => 'index', :neighborhood => /[a-z-]+/
  map.connect     '/search/:country/:state/:city/n/:neighborhood/:what', :controller => 'search', :action => 'index', :neighborhood => /[a-z-]+/
  map.connect     '/search/:country/:state/:city/n/:neighborhood', :controller => 'search', :action => 'neighborhood', :neighborhood => /[a-z-]+/
  map.connect     '/search/:country/:state/:city/tag/:tag', :controller => 'search', :action => 'index', :city => /[a-z-]+/ # city must be lowercase
  map.connect     '/search/:country/:state/:city/:what', :controller => 'search', :action => 'index', :city => /[a-z-]+/ # city must be lowercase
  map.connect     '/search/:country/:state/:city', :controller => 'search', :action => 'city', :city => /[a-z-]+/ # city must be lowercase
  map.connect     '/search/:country/:state/:zip/tag/:tag', :controller => 'search', :action => 'index', :zip => /\d{5}/ # zip must be 5 digits
  map.connect     '/search/:country/:state/:zip/:what', :controller => 'search', :action => 'index', :zip => /\d{5}/ # zip must be 5 digits
  map.connect     '/search/:country/:state/:zip', :controller => 'search', :action => 'zip', :zip => /\d{5}/ # zip must be 5 digits
  map.connect     '/search/:country/:state', :controller => 'search', :action => 'state', :state => /[a-z]{2}/ # state must be 2 letters
  map.connect     '/search/:country', :controller => 'search', :action => 'country', :country => /[a-z]{2}/ # country must be 2 letters

  
  # tag group routes
  map.resources   :taggs
  
  # zip routes
  map.connect     '/zips/error/:locality', :controller => 'zips', :action => 'error'
  map.connect     '/zips/:country/:state/:city', :controller => 'zips', :action => 'city'
  map.connect     '/zips/:country/:state', :controller => 'zips', :action => 'state'
  map.connect     '/zips/:country', :controller => 'zips', :action => 'country', :country => /[a-z]{2}/ # country must be 2 letters

  map.resources   :zips, :only => [:index]
  
  # map the root to the home controller
  map.root        :controller => 'home', :action => 'index'
  
  map.about       '/about', :controller => 'home', :action => 'about'
  
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
