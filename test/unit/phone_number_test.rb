require 'test/test_helper'

class PhoneNumberTest < ActiveSupport::TestCase
  
  should_validate_presence_of   :name
  should_validate_presence_of   :address
  
  context "create phone number" do
    context "with invalid number" do
      setup do
        @phone = PhoneNumber.create(:name => "Mobile", :address => "5551234")
      end

      should_not_change("PhoneNumber.count") { PhoneNumber.count }

      should "not be valid" do
        assert_equal false, @phone.valid?
      end
    end

    context "with no callable" do
      setup do
        @phone = PhoneNumber.create(:name => "Work", :address => "5559999999")
      end

      should_not_change("PhoneNumber.count") { PhoneNumber.count }
    end

    context "with callable and valid number" do
      setup do
        @user  = Factory(:user)
        @phone = @user.phone_numbers.create(:name => "Work", :address => "5559999999")
      end

      should_change("PhoneNumber.count", :by => 1) { PhoneNumber.count }

      should "increment user.phone_numbers_count" do
        @user.reload
        assert_equal 1, @user.phone_numbers_count
      end

      should "have state 'unverified'" do
        assert_equal 'unverified', @phone.state
      end
    end
    
    context "with callable and number with extra chars" do
      setup do
        @user  = Factory(:user)
        @phone = @user.phone_numbers.create(:name => "Mobile", :address => "555-999-9999")
      end

      should_change("PhoneNumber.count", :by => 1) { PhoneNumber.count }

      should "increment user.phone_numbers_count" do
        @user.reload
        assert_equal 1, @user.phone_numbers_count
      end

      should "normalize phone number" do
        assert_equal "5559999999", @phone.address
      end
    end
  end

  context "duplicate phone numbers" do
    setup do
      @user1  = Factory(:user)
      @phone1 = @user1.phone_numbers.create(:name => 'Mobile', :address => "5559999999")
      @user1.reload
      assert_equal 1, @user1.phone_numbers_count
    end

    context "add same phone number" do
      setup do
        @user2  = Factory(:user)
        @phone2 = @user2.phone_numbers.create(:name => 'Mobile', :address => "5559999999")
        puts @phone2.errors.full_messages
        @user2.reload
      end
      
      should_change("PhoneNumber.count", :by => 1) { PhoneNumber.count }
    end
  end

  context "remove phone number" do
    setup do
      @user   = Factory(:user)
      @phone  = @user.phone_numbers.create(:name => 'Mobile', :address => "5559999999")
      @user.reload
      assert_equal 1, @user.phone_numbers_count
      @user.phone_numbers.delete(@phone)
    end

    should "decrement user.phone_numbers_count" do
      assert_equal 0, @user.reload.phone_numbers_count
    end
  end
end