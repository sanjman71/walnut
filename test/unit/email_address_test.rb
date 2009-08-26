require 'test/test_helper'

class EmailAddressTest < ActiveSupport::TestCase
  
  should_validate_presence_of   :address
  
  context "create email address" do
    context "with no emailable" do
      setup do
        @email = EmailAddress.create(:address => "a@b.com")
      end
      
      should_not_change("EmailAddress.count") { EmailAddress.count }
      
      should "be invalid" do
        assert_equal false, @email.valid?
      end
      
      should "have error on emailable" do
        assert_true @email.errors.on(:emailable)
      end
    end

    context "with emailable" do
      setup do
        @user   = Factory(:user)
        @email  = @user.email_addresses.create(:address => "a@b.com")
      end

      should_change("EmailAddress.count") { EmailAddress.count }
      
      should "have priority of 1" do
        assert_equal 1, @email.priority
      end
      
      should "increment user.email_addresses_count" do
        @user.reload
        assert_equal 1, @user.email_addresses_count
      end
    end
  end

  context "remove email address" do
    should "decrement user.email_addresses_count" do
      @user   = Factory(:user)
      @email  = @user.email_addresses.create(:address => "a@b.com")
      @user.reload
      assert_equal 1, @user.email_addresses_count
      @user.email_addresses.delete(@email)
      @user.reload
      assert_equal [], @user.email_addresses
      assert_equal 0, @user.email_addresses_count
    end
  end
end