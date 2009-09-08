require 'test/test_helper'

class RpxControllerTest < ActionController::TestCase

  should_route :get,  '/rpx/login', :controller => 'rpx', :action => 'login'

  context "rpx login" do
    context "create admin user with rpx token" do
      setup do
        # stub RPXNow
        @rpx_hash = {:name=>'sanjay', :email=>'sanjay@walnutindustries.com', :identifier=>"https://www.google.com/accounts/o8/id?id=AItOawmaOlyYezg_WfbgP_qjaUyHjmqZD9qNIVM", :username => 'sanjman71'}
        RPXNow.stubs(:user_data).returns(@rpx_hash)
        get :login, :token => '12345'
        @user = User.with_email("sanjay@walnutindustries.com").first
      end

      should_respond_with :redirect
      should_redirect_to("root path") { "/" }
      
      should_change("User.count", :by => 1) { User.count }

      should_assign_to :data
      
      should "assign user email identifier" do
        @email = @user.primary_email_address
        assert_equal 'https://www.google.com/accounts/o8/id?id=AItOawmaOlyYezg_WfbgP_qjaUyHjmqZD9qNIVM', @email.identifier
      end

      should "assign 'admin' and 'user manager' roles" do
        assert_equal ['admin', 'user manager'], @user.roles.collect(&:name).sort
      end

      should "assign 'user manager' role on user" do
        assert_equal ['user manager'], @user.roles_on(@user).collect(&:name).sort
      end

      should "create user in passive state" do
        assert_equal "passive", @user.state
      end
      
      should_set_session(:user_id) { User.with_email("sanjay@walnutindustries.com").first.id }
      should_set_the_flash_to /Logged in successfully/i
    end

    context "create regular user with rpx token" do
      setup do
        # stub RPXNow
        @rpx_hash = {:name=>'sanjay',:email=>'sanjay@peanut.com',:identifier=>"https://www.google.com/accounts/o8/id?id=AItOawmaOlyYezg_WfbgP_qjaUyHjmqZD9qNIVM", :username => 'sanjman71'}
        RPXNow.stubs(:user_data).returns(@rpx_hash)
        get :login, :token => '12345'
      end

      should_respond_with :redirect
      should_redirect_to("root path") { "/" }
      
      should_not_change("User.count") { User.count }

      should_set_the_flash_to /This feature is coming soon/i
    end
    
    # context "create regular user using rpx token" do
    #   setup do
    #     # stub RPXNow
    #     @rpx_hash = {:name=>'sanjay',:email=>'sanjay@peanut.com',:identifier=>"https://www.google.com/accounts/o8/id?id=AItOawmaOlyYezg_WfbgP_qjaUyHjmqZD9qNIVM", :username => 'sanjman71'}
    #     RPXNow.stubs(:user_data).returns(@rpx_hash)
    #     get :login, :token => '12345'
    #   end
    # 
    #   should_respond_with :redirect
    #   should_redirect_to("root path") { "/" }
    #   
    #   should_change("User.count", :by => 1) { User.count }
    # 
    #   should_assign_to :data
    #   
    #   should "assign user identifier" do
    #     @user = User.find_by_email("sanjay@peanut.com")
    #     assert_equal 'https://www.google.com/accounts/o8/id?id=AItOawmaOlyYezg_WfbgP_qjaUyHjmqZD9qNIVM', @user.identifier
    #   end
    #   
    #   should "not assign admin role to user" do
    #     @user = User.find_by_email("sanjay@peanut.com")
    #     assert_equal [], @user.roles.collect(&:name)
    #   end
    # 
    #   should_set_session(:user_id) { User.find_by_email("sanjay@peanut.com").id }
    #   should_set_the_flash_to /User sanjay was successfully created/i
    # end
    
    context "create session with rpx token" do
      setup do
        # stub RPXNow
        @rpx_hash = {:name=>'Sanjay',:email=>'sanjay@walnutindustries.com',:identifier=>"https://www.google.com/accounts/o8/id?id=AItOawmaOlyYezg_WfbgP_qjaUyHjmqZD9qNIVM", :username => 'sanjman71'}
        RPXNow.stubs(:user_data).returns(@rpx_hash)
        # stub user
        @user = Factory(:user, :name => "Sanjay")
        @user.email_addresses.create(:address => "sanjay@walnutindustries.com")
        User.stubs(:with_identifier).with("https://www.google.com/accounts/o8/id?id=AItOawmaOlyYezg_WfbgP_qjaUyHjmqZD9qNIVM").returns([@user])
        get :login, :token => '12345'
      end

      should_respond_with :redirect
      should_redirect_to("root path") { "/" }

      # for the factory user, which is the same as the session user
      should_change("User.count", :by => 1) { User.count }

      should_assign_to :data
      
      should_set_session(:user_id) { @user.id }
      should_set_the_flash_to /Logged in successfully/i
    end
  end
end