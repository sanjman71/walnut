require 'test/test_helper'
require 'test/factories'

class UserTest < ActiveSupport::TestCase

  context "create user" do
    context "without a password or rpx" do
      setup do
        @user1 = User.create(:name => "User 1")
      end

      should_not_change("User.count") { User.count }

      should "require password" do
        assert !@user1.errors.on(:password).empty?
      end
    end

    context "with a password and email" do
      setup do
        options = Hash[:password => 'secret', :password_confirmation => 'secret', :email => "user1@walnut.com"]
        @user1  = User.create_or_reset(options)
      end

      should_change("User.count", :by => 1) { User.count }
      should_change("EmailAddress.count", :by => 1) { EmailAddress.count }

      should "not set user rpx flag" do
        assert_equal 0, @user1.rpx
      end

      should "increment user.email_addresses_count" do
        assert_equal 0, @user1.email_addresses_count
      end

      should "add to user.email_addresses collection" do
        assert_equal ["user1@walnut.com"], @user1.email_addresses.collect(&:address)
      end

      should "have user.email_address" do
        assert_equal "user1@walnut.com", @user1.reload.email_address
      end

      should "create user in active state" do
        assert_equal "active", @user1.state
      end

      should "create email in unverified state" do
        @email = @user1.primary_email_address
        assert_equal "unverified", @email.state
      end

      should "not set user rpx flag" do
        assert_equal 0, @user1.rpx
        assert_false @user1.rpx?
      end
    end

    context "with a password and email_addresses_attributes" do
      setup do
        options = Hash[:name => "User 1", :password => 'secret', :password_confirmation => 'secret', :email_addresses_attributes => [{:address => "user1@walnut.com"}]]
        @user1  = User.create_or_reset(options)
      end

      should_change("User.count", :by => 1) { User.count }
      should_change("EmailAddress.count", :by => 1) { EmailAddress.count }

      should "increment user.email_addresses_count" do
        assert_equal 0, @user1.email_addresses_count
      end

      should "add to user.email_addresses collection" do
        assert_equal ["user1@walnut.com"], @user1.email_addresses.collect(&:address)
      end

      should "have user.email_address" do
        assert_equal "user1@walnut.com", @user1.reload.email_address
      end

      should "not set user rpx flag" do
        assert_equal 0, @user1.rpx
        assert_false @user1.rpx?
      end
    end

    context "with rpx" do
      setup do
        @user1 = User.create_rpx("User 1", "user1@walnut.com", "https://www.google.com/accounts/o8/id?id=AItOawmaOlyYezg_WfbgP_qjaUyHjmqZD9qNIVM")
      end

      should_change("User.count", :by => 1) { User.count }
      should_change("EmailAddress.count", :by => 1) { EmailAddress.count }

      should "set user rpx flag" do
        assert_equal 1, @user1.rpx
        assert_true @user1.rpx?
      end

      should "add to user.email_addresses collection" do
        assert_equal ["user1@walnut.com"], @user1.email_addresses.collect(&:address)
        assert_equal ["https://www.google.com/accounts/o8/id?id=AItOawmaOlyYezg_WfbgP_qjaUyHjmqZD9qNIVM"], @user1.email_addresses.collect(&:identifier)
      end

      should "have user.email_address" do
        assert_equal "user1@walnut.com", @user1.reload.email_address
      end
      
      should "create user in active state" do
        assert_equal "passive", @user1.state
      end
      
      should "create email in verfied state" do
        @email = @user1.primary_email_address
        assert_equal "verified", @email.state
      end
    end

  end

  context "caldav token" do
    setup do
      @user2 = User.create(:name => "User 2", :password => "secret", :password_confirmation => "secret")
    end
    
    should "assign a cal_dav_token" do
      assert !(@user2.cal_dav_token.blank?)
    end
    
  end

end
