# This controller handles the login/logout function of the site.  
class SessionsController < ApplicationController

  include UserSessionHelper

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
      redirect_path = session_initialize(@user)
      redirect_back_or_default(redirect_path) and return
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
