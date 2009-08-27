require 'test/test_helper'

class StateTest < ActiveSupport::TestCase
  should_belong_to    :country
  should_have_many    :cities
  should_have_many    :locations
  
  def setup
    @us = Factory(:us)
  end
  
  context "state" do
    context "illinos" do
      setup do
        @il = State.create(:name => "Illinois", :code => "IL", :country => @us)
      end
      
      should_change("State.count", :by => 1) { State.count }
  
      should "have to_s method return Illinois" do
        assert_equal "Illinois", @il.to_s
      end
      
      should "have to_param method return il" do
        assert_equal "il", @il.to_param
      end
    end
  end
end
