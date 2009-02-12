require 'test/test_helper'
require 'test/factories'

class ZipTest < ActiveSupport::TestCase

  should_belong_to    :state
  should_have_many    :cities
  
  def setup
    @us   = Factory(:us)
    @il   = Factory(:state, :name => "Illinois", :code => "IL", :country => @us)
    @ny   = Factory(:state, :name => "New York", :code => "NY", :country => @us)
  end
  
  context "zip" do
    context "60654" do
      setup do
        @zip = Zip.create(:name => "60654", :state => @il)
      end
      
      should_change "Zip.count", :by => 1

      should "have to_s method return 60654" do
        assert_equal "60654", @zip.to_s
      end
      
      should "have to_param method return 60654" do
        assert_equal "60654", @zip.to_param
      end
    end
    
    context "invalid zip 1111" do
      setup do
        @zip = Zip.create(:name => "1111", :state => @il)
      end
      
      should_not_change "Zip.count"
    end
  end
  
end