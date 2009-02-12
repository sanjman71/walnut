require 'test/test_helper'
require 'test/factories'

class CityTest < ActiveSupport::TestCase

  should_belong_to    :state
  should_have_many    :zips
  should_have_many    :neighborhoods
  
  def setup
    @us   = Factory(:us)
    @il   = Factory(:state, :name => "Illinois", :code => "IL", :country => @us)
    @ny   = Factory(:state, :name => "New York", :code => "NY", :country => @us)
  end
  
  context "city" do
    context "chicago" do
      setup do
        @chicago = City.create(:name => "Chicago", :state => @il)
      end
      
      should_change "City.count", :by => 1
      
      should "have to_param method return chicago" do
        assert_equal "chicago", @chicago.to_param
      end
      
      should "have to_s method return Chicago" do
        assert_equal "Chicago", @chicago.to_s
      end
    end
    
    context "new york" do
      setup do
        @new_york = City.create(:name => "New York", :state => @ny)
      end

      should_change "City.count", :by => 1
      
      should "have to_param method return new-york" do
        assert_equal "new-york", @new_york.to_param
      end
    end
  end
  
end
