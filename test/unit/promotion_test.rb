require 'test/test_helper'

class PromotionTest < ActiveSupport::TestCase
  
  should_validate_presence_of     :code
  should_validate_presence_of     :uses_allowed
  should_validate_presence_of     :discount
  should_validate_presence_of     :units

  context "code uniqueness" do
    setup do
      @promotion = Promotion.create(:code => "abc", :uses_allowed => 5, :discount => 5, :units => 'dollars')
      assert_valid @promotion
    end

    should "not allow promotion with same code" do
      @promotion2 = Promotion.create(:code => "abc", :uses_allowed => 5, :discount => 5, :units => 'dollars')
      assert_not_valid @promotion2
    end
  end
  
  context "create with dollars" do
    setup do
      @promotion = Promotion.create(:code => "abc", :uses_allowed => 5, :discount => 5, :units => 'dollars')
    end

    should_change("Promotion.count", :by => 1) { Promotion.count }
    
    should "change units to cents" do
      assert_equal 'cents', @promotion.units
    end
    
    should "multiply discount by 100" do
      assert_equal 500.0, @promotion.discount
    end
  end

  context "uses remaining" do
    context "not empty" do
      setup do
        @promotion = Promotion.create(:code => "abc", :uses_allowed => 5, :discount => 5, :units => 'percent')
      end

      should_change("Promotion.count", :by => 1) { Promotion.count }

      should "have remaining == uses_allowed" do
        assert_equal 5, @promotion.remaining
      end

      should "not be empty" do
        assert_false @promotion.empty?
      end

      should "be redeemable" do
        assert_true @promotion.redeemable?
      end
    end

    context "empty" do
      setup do
        @promotion = Promotion.create(:code => "abc", :uses_allowed => 0, :discount => 5, :units => 'percent')
      end

      should_change("Promotion.count", :by => 1) { Promotion.count }

      should "have remaining == uses_allowed" do
        assert_equal 0, @promotion.remaining
      end

      should "be empty" do
        assert_true @promotion.empty?
      end

      should "not be redeemable" do
        assert_false @promotion.redeemable?
      end
    end
  end

  context "expires_at" do
    context "with no expiration" do
      setup do
        @promotion = Promotion.create(:code => "abc", :uses_allowed => 5, :discount => 5, :units => 'percent')
      end

      should_change("Promotion.count", :by => 1) { Promotion.count }

      should "have no expiration" do
        assert_nil @promotion.expires_at
      end

      should "not be expired" do
        assert_false @promotion.expired?
      end

      should "be redeemable" do
        assert_true @promotion.redeemable?
      end
    end

    context "with a future expiration" do
      setup do
        @promotion = Promotion.create(:code => "abc", :uses_allowed => 5, :discount => 5, :units => 'percent', :expires_at => Time.now + 3.days)
      end

      should_change("Promotion.count", :by => 1) { Promotion.count }

      should "have an expiration" do
        assert_not_nil @promotion.expires_at
      end

      should "not be expired" do
        assert_false @promotion.expired?
      end

      should "be redeemable" do
        assert_true @promotion.redeemable?
      end
    end

    context "with a past expiration" do
      setup do
        @promotion = Promotion.create(:code => "abc", :uses_allowed => 5, :discount => 5, :units => 'percent', :expires_at => Time.now - 3.days)
      end

      should_change("Promotion.count", :by => 1) { Promotion.count }

      should "have an expiration" do
        assert_not_nil @promotion.expires_at
      end

      should "be expired" do
        assert_true @promotion.expired?
      end

      should "not be redeemable" do
        assert_false @promotion.redeemable?
      end
    end
  end

  context "percentage discount" do
    context "with no minimum" do
      setup do
        @promotion  = Promotion.create(:code => 'abc', :uses_allowed => 5,  :discount => 10, :units => 'percent')
        @prices     = @promotion.calculate(5)
      end

      should "calculate discount" do
        assert_equal [5.0, 0.5, 4.5], @prices
      end
    end

    context "with minimum" do
      setup do
        @promotion  = Promotion.create(:code => 'abc', :uses_allowed => 5,  :discount => 10, :units => 'percent', :minimum => 5)
        @prices     = @promotion.calculate(3)
      end

      should "calculate discount" do
        assert_equal [3.0, 0, 3.0], @prices
      end
    end
    
    context "with 100% discount" do
      setup do
        @promotion  = Promotion.create(:code => 'abc', :uses_allowed => 5,  :discount => 100, :units => 'percent', :minimum => 5)
        @prices     = @promotion.calculate(10)
      end

      should "calculate discount" do
        assert_equal [10.0, 10.0, 0.0], @prices
      end
    end
  end
  
  context "cents discount" do
    context "with no minimum" do
      context "and discount < price" do
        setup do
          @promotion  = Promotion.create(:code => 'abc', :uses_allowed => 5,  :discount => 250, :units => 'cents')
          @prices     = @promotion.calculate(500)
        end

        should "allow discount" do
          assert_equal [500.0, 250.0, 250.0], @prices
        end
      end

      context "and discount = price" do
        setup do
          @promotion  = Promotion.create(:code => 'abc', :uses_allowed => 5,  :discount => 500, :units => 'cents')
          @prices     = @promotion.calculate(500)
        end

        should "allow discount" do
          assert_equal [500.0, 500.0, 0.0], @prices
        end
      end

      context "and discount > price" do
        setup do
          @promotion  = Promotion.create(:code => 'abc', :uses_allowed => 5,  :discount => 250, :units => 'cents')
          @prices     = @promotion.calculate(200)
        end

        should "allow discount" do
          assert_equal [200.0, 200.0, 0], @prices
        end
      end
    end

    context "with minimum" do
      context "and price < minimum" do
        setup do
          @promotion  = Promotion.create(:code => 'abc', :uses_allowed => 5,  :discount => 250, :units => 'cents', :minimum => 1000)
          @prices     = @promotion.calculate(500)
        end

        should "not allow discount" do
          assert_equal [500.0, 0, 500.0], @prices
        end
      end
    end
  end

  context "redemption" do
    setup do
      @user       = Factory(:user)
      @promotion  = Promotion.create(:code => 'abc', :uses_allowed => 5,  :discount => 10, :units => 'percent', :minimum => 5)
    end

    should_change("Promotion.count", :by => 1) { Promotion.count }

    context "redeem" do
      setup do
        @redemption = @promotion.redeem(@user)
        @promotion.reload
      end

      should_change("PromotionRedemption.count", :by => 1) { PromotionRedemption.count }

      should "increment promotion redemptions_count" do
        assert_equal 1, @promotion.redemptions_count
      end

      should "decrement promotion remaining" do
        assert_equal 4, @promotion.remaining
      end
      
      should "set user as redeemer" do
        assert_equal @user, @redemption.redeemer
      end
      
      context "remove promotion" do
        setup do
          @promotion.destroy
        end
        
        should "remove associated redemptions" do
          assert_equal 0, PromotionRedemption.count
        end
        
        should "have 0 promotions" do
          assert_equal 0, Promotion.count
        end
      end
    end
  end
end