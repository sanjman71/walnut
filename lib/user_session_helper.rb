module UserSessionHelper
  
  protected

  def session_initialize(user)
    # Protects against session fixation attacks, causes request forgery
    # protection if user resubmits an earlier form using back
    # button. Uncomment if you understand the tradeoffs.
    
    # cache the return to value (if it exists) before we reset the ression
    return_to         = session[:return_to]
    reset_session
    self.current_user = user
    new_cookie_flag   = (params[:remember_me] == "1")
    handle_remember_cookie! new_cookie_flag
    flash[:notice]    = "Logged in successfully"
    
    # return the redirect path
    return_to || '/'
  end
end