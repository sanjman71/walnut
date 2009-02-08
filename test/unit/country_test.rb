require 'test/test_helper'

class CountryTest < ActiveSupport::TestCase
  should_have_many    :states
  should_have_many    :areas
  
  context "country" do
    context "us" do
      setup do
        @us = Country.create(:name => "United States", :code => "US")
      end
      
      should_change "Country.count", :by => 1
  
      should "have to_s method return United States" do
        assert_equal "United States", @us.to_s
      end
      
      should "have to_param method return us" do
        assert_equal "us", @us.to_param
      end
      
      should "have default return us" do
        assert_equal @us, Country.default
      end
    end
  end
  
end
