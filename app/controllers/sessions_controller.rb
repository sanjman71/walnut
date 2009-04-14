# This controller handles the login/logout function of the site.  
class SessionsController < ApplicationController

  def new
    @user = User.new
    
    respond_to do |format|
      format.html
    end
  end

  def create
    logout_keeping_session!
    
    # authenticate user
    user = User.authenticate(params[:email], params[:password])
    
    if user
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
      redirect_back_or_default(return_to || '/') and return
    else
      note_failed_signin
      @user        = User.new
      @email       = params[:email]
      @remember_me = params[:remember_me]

      render(:action => 'new') and return
    end
  end  

  def destroy
    logout_killing_session!
    flash[:notice] = "You have been logged out."
    redirect_back_or_default('/')
  end

  protected

  # Track failed login attempts
  def note_failed_signin
    flash.now[:error] = "Couldn't log you in as '#{params[:email]}'"
    logger.warn "Failed login for '#{params[:email]}' from #{request.remote_ip} at #{Time.now.utc}"
  end
end
