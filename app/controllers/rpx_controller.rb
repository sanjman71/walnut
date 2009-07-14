class RpxController < ApplicationController

  include UserSessionHelper
  
  def login
    raise Exception unless @data = RPXNow.user_data(params[:token])
    
    @user = User.find_by_identifier(@data[:identifier])
    
    if @user.blank?
      # create user using rpx data
      @user = User.create(:name => @data[:name], :email => @data[:email], :identifier => @data[:identifier])
    
      @user.register! if @user.valid?
      success = @user && @user.valid?
    
      # raise Exception, "#{@user.errors.full_messages}"
      
      if success && @user.errors.empty?
        flash[:notice] = "User #{@user.name} was successfully created."
        redirect_back_or_default("/") and return
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