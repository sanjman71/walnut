class RpxController < ApplicationController

  include UserSessionHelper
  
  def login
    raise Exception unless @data = RPXNow.user_data(params[:token])

    @user = User.find_by_identifier(@data[:identifier])
    
    if @user.blank?
      # create user using rpx data
      @user = User.create(:name => @data[:name], :email => @data[:email], :identifier => @data[:identifier])

      if @user.valid?
        # register user
        @user.register!

        # create user session
        redirect_path = session_initialize(@user)

        if ADMIN_USER_EMAILS.include?(@user.email)
          # grant user the 'admin' role
          @user.grant_role('admin')
        end
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