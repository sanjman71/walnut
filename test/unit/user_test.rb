require 'test/test_helper'

class UserTest < ActiveSupport::TestCase

  context "create user" do
    context "with no password or confirmation" do
      setup do
        @user1 = User.create(:name => "User 1")
      end

      should_change("User.count") { User.count }

      should "create user in active state" do
        assert_equal "active", @user1.state
      end
    end

    context "with an empty password and confirmation" do
      setup do
        @user1 = User.create(:name => "User 1", :password => '', :password_confirmation => '')
      end

      should_change("User.count") { User.count }

      should "create user in active state" do
        assert_equal "active", @user1.state
      end
    end

    context "with password and confirmation mismatch" do
      setup do
        @user1 = User.create(:name => "User 1", :password => "secret", :password_confirmation => "secretx")
      end

      should_not_change("User.count") { User.count }

      should "require password" do
        assert !@user1.errors.on(:password).empty?
      end
    end

    context "with an empty nested email address hash" do
      setup do
        options = Hash[:name => "User 1", :password => 'secret', :password_confirmation => 'secret',
                       :email_addresses_attributes => { "0" => {:address => ""}}]
        @user1  = User.create(options)
      end

      should_change("User.count", :by => 1) { User.count }
      should_not_change("EmailAddress.count") { EmailAddress.count }
    end

    context "with an invalid nested email address hash" do
      setup do
        options = Hash[:name => "User 1", :password => 'secret', :password_confirmation => 'secret',
                       :email_addresses_attributes => { "0" => {:address => "xyz"}}]
        @user1  = User.create(options)
      end

      should_not_change("User.count") { User.count }
      should_not_change("EmailAddress.count") { EmailAddress.count }
    end

    context "with a duplicate email address" do
      setup do
        @user   = Factory(:user, :name => "User")
        @email  = @user.email_addresses.create(:address => "user1@walnut.com")
        options = Hash[:name => "User 1", :password => 'secret', :password_confirmation => 'secret',
                       :email_addresses_attributes => { "0" => {:address => "user1@walnut.com"}}]
        @user1  = User.create(options)
      end

      should "not create user1" do
        assert_false @user1.valid?
      end
    end

    context "with a nested email address hash" do
      setup do
        options = Hash[:name => "User 1", :password => 'secret', :password_confirmation => 'secret',
                       :email_addresses_attributes => { "0" => {:address => "user1@walnut.com"}}]
        @user1  = User.create(options)
      end

      should_change("User.count", :by => 1) { User.count }
      should_change("EmailAddress.count", :by => 1) { EmailAddress.count }

      should "not set user rpx flag" do
        assert_equal 0, @user1.rpx
        assert_false @user1.rpx?
      end

      should "increment user.email_addresses_count" do
        assert_equal 1, @user1.reload.email_addresses_count
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

      # should not send user created message
      should_not_change("delayed job count") { Delayed::Job.count }

      context "then delete user" do
        setup do
          @user1.destroy
        end

        should_change("User.count", :by => -1) { User.count }
        should_change("EmailAddress.count", :by => -1) { EmailAddress.count }
      end
    end

    context "with a nested email address array" do
      setup do
        options = Hash[:name => "User 1", :password => 'secret', :password_confirmation => 'secret',
                       :email_addresses_attributes => [{:address => "user1@walnut.com"}]]
        @user1  = User.create(options)
        # puts @user1.errors.full_messages
      end
    
      should_change("User.count", :by => 1) { User.count }
      should_change("EmailAddress.count", :by => 1) { EmailAddress.count }
    
      should "increment user.email_addresses_count" do
        assert_equal 1, @user1.reload.email_addresses_count
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
    
      should "have password?" do
        assert_true @user1.reload.password?
      end
    
      # should not send user created message
      should_not_change("delayed job count") { Delayed::Job.count }
    end

    context "with an empty nested phone number array" do
      setup do
        options = Hash[:name => "User 1", :password => 'secret', :password_confirmation => 'secret',
                       :phone_numbers_attributes => [{:address => "", :name => ""}]]
        @user1  = User.create(options)
      end

      should_change("User.count", :by => 1) { User.count }
      should_not_change("PhoneNumber.count") { PhoneNumber.count }
    end

    context "with an invalid nested phone number array" do
      setup do
        options = Hash[:name => "User 1", :password => 'secret', :password_confirmation => 'secret',
                       :phone_numbers_attributes => [{:address => "3125551212", :name => ""}]]
        @user1  = User.create(options)
      end

      should_not_change("User.count") { User.count }
      should_not_change("PhoneNumber.count") { PhoneNumber.count }
    end
    
    context "with a nested phone number array" do
      setup do
        options = Hash[:name => "User 1", :password => 'secret', :password_confirmation => 'secret',
                       :phone_numbers_attributes => [{:address => "3125551212", :name => "Mobile"}]]
        @user1  = User.create(options)
      end

      should_change("User.count", :by => 1) { User.count }
      should_change("PhoneNumber.count", :by => 1) { PhoneNumber.count }

      should "increment user.phone_numbers_count" do
        assert_equal 1, @user1.reload.phone_numbers_count
      end

      should "add to user.phone_numbers collection" do
        assert_equal ["3125551212"], @user1.phone_numbers.collect(&:address)
      end

      should "have user.phone_number" do
        assert_equal "3125551212", @user1.reload.phone_number
      end

      context "then delete user" do
        setup do
          @user1.destroy
        end

        should_change("User.count", :by => -1) { User.count }
        should_change("PhoneNumber.count", :by => -1) { PhoneNumber.count }
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
        assert_equal "active", @user1.state
      end

      should "create email in verified state" do
        @email = @user1.primary_email_address
        assert_equal "verified", @email.state
      end

      should "not have password?" do
        assert_false @user1.reload.password?
      end

      # should *not* send user created message
      should_not_change("delayed job count") { Delayed::Job.count }
    end

    context "with phone required" do
      context "but missing" do
        setup do
          @user1 = User.create(:name => "User 1", :password => "secret", :password_confirmation => "secret", :preferences_phone => 'required')
        end

        should_change("User.count", :by => 1) { User.count }

        should "create user in incomplete state" do
          assert_equal 'incomplete', @user1.state
        end

        context "and add phone as phone object" do
          setup do
            @user1.phone_numbers.create(:name => 'Mobile', :address => '5551112222')
          end

          should_change("PhoneNumber.count", :by => 1) { PhoneNumber.count }

          should "change user state to active" do
            assert_equal 'active', @user1.reload.state
          end
        end

        context "and add phone as attributes hash" do
          setup do
            @user1.update_attributes({:phone_numbers_attributes => {"1" => {:address => "5551112222", :name => "Mobile"}}})
          end

          should_change("PhoneNumber.count", :by => 1) { PhoneNumber.count }

          should "change user state to active" do
            assert_equal 'active', @user1.reload.state
          end
        end
      end
      
      context "and present" do
        setup do
          @user1 = User.create(:name => "User 1", :password => "secret", :password_confirmation => "secret", :preferences_phone => 'required',
                               :phone_numbers_attributes => [{:address => "3125551212", :name => "Mobile"}])
        end

        should_change("User.count", :by => 1) { User.count }
        should_change("PhoneNumber.count", :by => 1) { PhoneNumber.count }

        should "create user in active state" do
          assert_equal 'active', @user1.state
        end

        context "and remove phone" do
          setup do
            @user1.phone_numbers.destroy(@user1.phone_numbers.first)
          end

          should_change("PhoneNumber.count", :by => -1) { PhoneNumber.count }

          should "change user state to incomplete" do
            assert_equal 'incomplete', @user1.reload.state
          end
        end
      end
    end

    context "with email required" do
      context "but missing" do
        setup do
          @user1 = User.create(:name => "User 1", :password => "secret", :password_confirmation => "secret", :preferences_email => 'required')
        end

        should_change("User.count", :by => 1) { User.count }

        should "create user in incomplete state" do
          assert_equal 'incomplete', @user1.state
        end

        context "and add email address as email object" do
          setup do
            @user1.email_addresses.create(:address => 'sanjay@jarna.com')
          end

          should_change("EmailAddress.count", :by => 1) { EmailAddress.count }

          should "change user state to active" do
            assert_equal 'active', @user1.reload.state
          end
        end

        context "and add email as attributes hash" do
          setup do
            @user1.update_attributes({:email_addresses_attributes => {"1" => {:address => "sanjay@jarna.com"}}})
          end

          should_change("EmailAddress.count", :by => 1) { EmailAddress.count }

          should "change user state to active" do
            assert_equal 'active', @user1.reload.state
          end
        end
      end

      context "and present" do
        setup do
          @user1 = User.create(:name => "User 1", :password => "secret", :password_confirmation => "secret", :preferences_email => 'required',
                               :email_addresses_attributes => [{:address => "user1@walnut.com"}])
        end

        should_change("User.count", :by => 1) { User.count }

        should "create user in active state" do
          assert_equal 'active', @user1.state
        end

        context "and remove email" do
          setup do
            @user1.email_addresses.destroy(@user1.email_addresses.first)
          end

          should_change("EmailAddress.count", :by => -1) { EmailAddress.count }

          should "change user state to incomplete" do
            assert_equal 'incomplete', @user1.reload.state
          end
        end
      end
    end

    context "with phone and email required" do
      setup do
        @user1 = User.create(:name => "User 1", :password => "secret", :password_confirmation => "secret",
                             :preferences_phone => 'required', :preferences_email => 'required')
      end

      should_change("User.count", :by => 1) { User.count }

      should "create user in incomplete state" do
        assert_equal 'incomplete', @user1.state
      end

      context "and add phone number" do
        setup do
          @user1.phone_numbers.create(:name => 'Mobile', :address => '5551112222')
        end

        should_change("PhoneNumber.count", :by => 1) { PhoneNumber.count }

        should "leave user in incomplete state" do
          assert_equal 'incomplete', @user1.reload.state
        end
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
