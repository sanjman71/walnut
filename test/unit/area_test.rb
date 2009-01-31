require 'test/test_helper'
require 'test/factories'

class AreaTest < ActiveSupport::TestCase
  
  context "create state area" do
    setup do
      @il   = Factory(:state, :name => "Illinois", :ab => "IL")
      @area = Area.create(:extent => @il)
    end

    should_change "Area.count", :by => 1
        
    should "have area extent == state" do
      assert_equal @il, @area.extent
    end

    context "create city area" do
      setup do 
        @chicago  = Factory(:city, :name => "Chicago", :state => @il)
        @area2    = Area.create(:extent => @chicago)
      end

      should_change "Area.count", :by => 1

      should "have area extent == city" do
        assert_equal @chicago, @area2.extent
      end
      
      context "try to create duplicate city area" do
        setup do
          @area3 = Area.create(:extent => @chicago)
        end

        should_not_change "Area.count"
      end
      
    end
  end
  
  
end
