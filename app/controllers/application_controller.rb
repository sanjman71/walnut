# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

class ApplicationController < ActionController::Base
  helper :all # include all helpers, all the time

  # Make the following methods available to all helpers
  helper_method :global_flash?
  
  # See ActionController::RequestForgeryProtection for details
  # Uncomment the :secret if you're not using the cookie session store
  protect_from_forgery # :secret => '7c342efc7bc88b372c5913ebad934c5e'
  
  # See ActionController::Base for details 
  # Uncomment this to filter the contents of submitted sensitive data parameters
  # from your application log (in this case, all fields with names like "password"). 
  # filter_parameter_logging :password
  
  # Default application layout
  layout 'home'
  
  # controls whether the flash may be displayed in the header, defaults to true
  def global_flash?
    @global_flash = true if @global_flash.nil?
    return @global_flash
  end
  
  def disable_global_flash
    @global_flash = false
  end

end
