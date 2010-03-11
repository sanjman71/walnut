require 'test/test_helper'

class SessionsControllerTest < ActionController::TestCase

  should_route :get, '/login', :controller => 'sessions', :action => 'new'

  def setup
    # initialize roles and privileges
    BadgesInit.roles_privileges
    @user       = Factory(:user, :name => "User", :password => 'user', :password_confirmation => 'user')
    @user_email = @user.email_addresses.create(:address => "user@walnut.com")
    assert @user_email.valid?
    @user_phone = @user.phone_numbers.create(:name => 'Mobile', :address => '6509999999')
    assert @user_phone.valid?
    assert_equal 'active', @user.state
  end

  context "create session (login)" do
    context "with email address" do
      setup do
        post :create, {:email => 'user@walnut.com', :password => 'user'}
      end

      should "set session user" do
        assert_equal @user.id, session[:user_id]
      end

      should_redirect_to("root path") { "/" }
    end

    context "with unique phone number" do
      setup do
        post :create, {:email => '650-999.9999', :password => 'user'}
      end

      should "set session user" do
        assert_equal @user.id, session[:user_id]
      end

      should_redirect_to("root path") { "/" }
    end

    context "with non-unique phone number" do
      setup do
        @user2 = Factory(:user, :name => "User2", :password => 'user', :password_confirmation => 'user')
        @user2_phone = @user2.phone_numbers.create(:name => 'Mobile', :address => '6509999999')
        assert @user2_phone.valid?
        post :create, {:email => '650-999.9999', :password => 'user'}
      end

      should_assign_to(:user)

      should "not set session user" do
        assert_nil session[:user_id]
      end

      should_respond_with :success
      should_render_template "sessions/new.html.haml"
    end

    context "for user with no password" do
      setup do
        @user2 = User.create(:name => "User2", :password => '', :password_confirmation => '')
        assert @user2.valid?
        @user2_email = @user2.email_addresses.create(:address => "user2@walnut.com")
        assert @user2_email.valid?
      end
      
      context "using no password" do
        setup do
          post :create, {:email => 'user2@walnut.com'}
        end

        should "set session user" do
          assert_equal @user2.id, session[:user_id]
        end

        should_redirect_to("root path") { "/" }
      end
      
      context "using a password" do
        setup do
          post :create, {:email => 'user2@walnut.com', :password => 'secret'}
        end

        should_assign_to(:user)

        should "not set session user" do
          assert_nil session[:user_id]
        end

        should_respond_with :success
        should_render_template "sessions/new.html.haml"
      end
    end

    context "for a user in incomplete state" do
      setup do
        @user.data_missing!
        assert_equal 'incomplete', @user.state
        post :create, {:email => 'user@walnut.com', :password => 'user'}
      end

      should "set session user" do
        assert_equal @user.id, session[:user_id]
      end

      should_redirect_to("root path") { "/" }
    end

    context "with return_to" do
      setup do
        post :create, {:email => 'user@walnut.com', :password => 'user', :return_to => "/users/#{@user.id}/edit"}
      end

      should_not_assign_to(:user)
      should_assign_to(:return_to)

      should_redirect_to("return_to path") { "/users/#{@user.id}/edit" }
    end
    
    context "from a mobile device" do
      setup do
        xhr :post, :create, {:email => 'user@walnut.com', :password => 'user', :mobile => '1'}
      end

      should "set session user" do
        assert_equal @user.id, session[:user_id]
      end

      should_respond_with_content_type "application/json"
      
      should "have response status of 200" do
        assert_equal '200 OK', @response.status
      end
    end
  end

end