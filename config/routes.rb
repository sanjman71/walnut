ActionController::Routing::Routes.draw do |map|
  # The priority is based upon order of creation: first created -> highest priority.

  # places error route
  map.connect     'places/error/:area', :controller => 'places', :action => 'error'
  
  # places [area, tag] routes
  map.connect     'places/search', :controller => 'places', :action => 'search'
  map.connect     'places/:country/:state/:city/n/:neighborhood/:what', :controller => 'places', :action => 'index', :neighborhood => /[a-z-]+/
  map.connect     'places/:country/:state/:city/n/:neighborhood', :controller => 'places', :action => 'neighborhood', :neighborhood => /[a-z-]+/
  map.connect     'places/:country/:state/:city/:what', :controller => 'places', :action => 'index', :city => /[a-z-]+/
  map.connect     'places/:country/:state/:city', :controller => 'places', :action => 'city', :city => /[a-z-]+/
  map.connect     'places/:country/:state/:zip/:what', :controller => 'places', :action => 'index', :zip => /\d{5}/
  map.connect     'places/:country/:state/:zip', :controller => 'places', :action => 'zip', :zip => /\d{5}/
  map.connect     'places/:country/:state', :controller => 'places', :action => 'state'
  map.connect     'places/:country', :controller => 'places', :action => 'country', :country => /[a-z]{2}/ # country must be 2 letters
  
  map.resources   :places, :only => [:index, :show]
  
  # chains routes
  map.connect     'chains/:name/:country', :controller => 'chains', :action => 'country'
  map.connect     'chains/:name/:country/:state', :controller => 'chains', :action => 'state'
  map.connect     'chains/:name/:country/:state/:city', :controller => 'chains', :action => 'city'
  
  map.resources   :chains, :only => [:index]
  
  # zip routes
  map.connect     'zips/error/:area', :controller => 'zips', :action => 'error'
  map.connect     'zips/:country/:state/:city', :controller => 'zips', :action => 'city'
  map.connect     'zips/:country/:state', :controller => 'zips', :action => 'state'
  map.connect     'zips/:country', :controller => 'zips', :action => 'country', :country => /[a-z]{2}/ # country must be 2 letters

  map.resources   :zips, :only => [:index]
  
  # map the root to the home controller
  map.root        :controller => 'home', :action => 'index'
  
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
