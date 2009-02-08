require 'test/test_helper'
require 'test/factories'

class NeighborhoodTest < ActiveSupport::TestCase
  should_belong_to    :city
  should_have_many    :areas
  
  def setup
    @us       = Factory(:us)
    @il       = Factory(:state, :name => "Illinois", :code => "IL", :country => @us)
    @chicago  = Factory(:city, :name => "Chicago", :state => @il)
  end
  
  context "neighborhood" do
    context "river north" do
      setup do
        @river_north = Neighborhood.create(:name => "River North", :city => @chicago)
      end
      
      should_change "Neighborhood.count", :by => 1
      
      should "have to_param method return river-north" do
        assert_equal "river-north", @river_north.to_param
      end
      
      should "have to_s method return River North" do
        assert_equal "River North", @river_north.to_s
      end
    end
  end
end