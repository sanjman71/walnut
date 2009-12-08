class PromotionExpiredError < StandardError; end
class PromotionEmptyError < StandardError; end

class Promotion < ActiveRecord::Base
  validates_presence_of     :code, :uses_allowed, :discount, :units
  validates_uniqueness_of   :code
  validates_inclusion_of    :units, :in => %w(cents percent)
  has_many                  :promotion_redemptions, :dependent => :destroy

  def before_validation_on_create
    if self.minimum.blank?
      self.minimum = 0.0
    end
    
    if self.units == 'dollars'
      # convert dollars to cents
      self.units    = 'cents'
      self.discount = self.discount * 100.0
    end

    self.redemptions_count = 0
  end

  def remaining
    self.uses_allowed - self.redemptions_count
  end
  
  def calculate(price)
    # use floats
    price_float = price.to_f

    # check minimum
    unless self.minimum.blank?
      if price_float < self.minimum
        # price does not meet minimum
        return [price_float, 0, price_float]
      end
    end

    case self.units
    when 'percent'
      # caculate percentage discount
      price_subtract  = price_float * self.discount/100
    when 'cents'
      # calculate cents discount
      price_subtract  = (price_float > self.discount) ? price_float - self.discount : price_float
    else
      price_subtract  = 0
    end

    price_discounted  = price_float - price_subtract

    [price_float, price_subtract, price_discounted]
  end

  def empty?
    self.remaining <= 0
  end
  
  def expired?
    !self.expires_at.blank? and self.expires_at < Time.now
  end

  def redeemable?
    # not empty and not expired
    !self.empty? and !self.expired?
  end
  
  def redeem(redeemer)
    unless self.redeemable?
      if self.expired?
        raise PromotionExpiredError
      end
    
      if empty?
        raise PromotionEmptyError
      end
    end

    @redemption = self.promotion_redemptions.create(:redeemer => redeemer)
  end
end