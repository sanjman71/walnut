require 'test/test_helper'
require 'test/factories'

class NeighborhoodTest < ActiveSupport::TestCase
  should_belong_to    :city
  should_have_many    :location_neighborhoods
  should_have_many    :locations
  
  def setup
    @us       = Factory(:us)
    @il       = Factory(:state, :name => "Illinois", :code => "IL", :country => @us)
    @chicago  = Factory(:city, :name => "Chicago", :state => @il)
    @suburbia = Factory(:city, :name => "Suburbia", :state => @il)
  end
  
  context "neighborhood" do
    context "add river north to chicago" do
      setup do
        @river_north = Neighborhood.create(:name => "River North", :city => @chicago)
        @chicago.reload
      end
      
      should_change "Neighborhood.count", :by => 1
      
      should "have to_param method return river-north" do
        assert_equal "river-north", @river_north.to_param
      end
      
      should "have to_s method return River North" do
        assert_equal "River North", @river_north.to_s
      end

      should "increment chicago neighborhoods count" do
        assert_equal 1, @chicago.neighborhoods_count
      end

      context "then move river north from chicago to suburbia" do
        setup do
          @river_north.city = @suburbia
          @river_north.save
          assert @river_north.valid?
          @chicago.reload
          @suburbia.reload
        end
        
        should_not_change "Neighborhood.count"

        should "decrement chicago neighborhoods count" do
          assert_equal 0, @chicago.neighborhoods_count
        end

        should "increment suburbia neighborhoods count" do
          assert_equal 1, @suburbia.neighborhoods_count
        end
        
      end
    end
  end
end