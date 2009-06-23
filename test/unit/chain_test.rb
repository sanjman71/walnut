require 'test/test_helper'
require 'test/factories'

class ChainTest < ActiveSupport::TestCase
  
  should_validate_presence_of   :name
  should_have_many              :places

  context "chain without a display name" do
    setup do
      @chain = Chain.create(:name => "Chain Store")
    end

    should "have display_name == Chain Store" do
      assert_equal "Chain Store", @chain.display_name
    end

    context "then set the display name" do
      setup do
        @chain.display_name = "McDonalds"
        @chain.save
        @chain.reload
      end

      should "have display_name == McDonalds" do
        assert_equal "McDonalds", @chain.display_name
      end
    end
  end
end
