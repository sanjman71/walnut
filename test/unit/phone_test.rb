require 'test/test_helper'
require 'test/factories'

class PhoneNumberTest < ActiveSupport::TestCase
  
  should_validate_presence_of   :name
  should_validate_presence_of   :number
  
  context "phone number" do
    context "with invalid number" do
      setup do
        @phone = PhoneNumber.create(:name => "Work", :number => "5551234")
      end
      
      should_not_change "PhoneNumber.count"
      
      should "have number marked as invalid" do
        assert_equal false, @phone.valid?
      end
    end
    
    context "with valid number" do
      setup do
        @phone = PhoneNumber.create(:name => "Work", :number => "5559999999")
      end
      
      should_change "PhoneNumber.count"
    end
  end
end