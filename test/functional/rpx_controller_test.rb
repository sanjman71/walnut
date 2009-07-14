require 'test/test_helper'

class RpxControllerTest < ActionController::TestCase

  should_route :get,  '/rpx/login', :controller => 'rpx', :action => 'login'

  context "rpx login" do
    context "create user using rpx token" do
      setup do
        # stub RPXNow
        @rpx_hash = {:name=>'sanjman71',:email=>'sanjman71@gmail.com',:identifier=>"https://www.google.com/accounts/o8/id?id=AItOawmaOlyYezg_WfbgP_qjaUyHjmqZD9qNIVM", :username => 'sanjman71'}
        RPXNow.stubs(:user_data).returns(@rpx_hash)
        get :login, :token => '12345'
      end

      should_respond_with :redirect
      should_redirect_to("root path") { "/" }
      
      should_change "User.count", :by => 1

      should_assign_to :data
      
      should "assign user identifier" do
        @user = User.find_by_email("sanjman71@gmail.com")
        assert_equal 'https://www.google.com/accounts/o8/id?id=AItOawmaOlyYezg_WfbgP_qjaUyHjmqZD9qNIVM', @user.identifier
      end
    end
    
    context "create session using rpx token" do
      setup do
        # stub RPXNow
        @rpx_hash = {:name=>'sanjman71',:email=>'sanjman71@gmail.com',:identifier=>"https://www.google.com/accounts/o8/id?id=AItOawmaOlyYezg_WfbgP_qjaUyHjmqZD9qNIVM", :username => 'sanjman71'}
        RPXNow.stubs(:user_data).returns(@rpx_hash)
        # stub user
        @user = Factory(:user, :name => "Sanjay", :email => "sanjay@jarna.com")
        User.stubs(:find_by_identifier).with("https://www.google.com/accounts/o8/id?id=AItOawmaOlyYezg_WfbgP_qjaUyHjmqZD9qNIVM").returns(@user)
        get :login, :token => '12345'
      end

      should_respond_with :redirect
      should_redirect_to("root path") { "/" }

      should_change "User.count", :by => 1 # for the factory user, which is the same as the session user

      should_assign_to :data
      
      should_set_session(:user_id) { @user.id }
      should_set_the_flash_to /Logged in successfully/i
    end
  end
end