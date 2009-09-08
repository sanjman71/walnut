class RpxController < ApplicationController

  include UserSessionHelper
  
  def login
    raise Exception unless @data = RPXNow.user_data(params[:token])

    @user = User.with_identifier(@data[:identifier]).first
    
    if @user.blank?
      # only allow certain users to login with rpx
      if defined?(ADMIN_USER_EMAILS) and !ADMIN_USER_EMAILS.include?(@data[:email])
        flash[:error] = "This feature is coming soon"
        redirect_to("/") and return
      end

      # create user using rpx data
      @user = User.create_rpx(@data[:name], @data[:email], @data[:identifier])
      
      if @user.valid?
        # create user session
        redirect_path = session_initialize(@user)
      end

      if @user.valid?
        redirect_back_or_default(redirect_path) and return
      else
        flash[:error] = @user.errors.full_messages.join("<br/>")
        render(:template => "sessions/new") and return
      end
    else
      # create user session
      redirect_path = session_initialize(@user)
      redirect_back_or_default(redirect_path) and return
    end
  end

end