class PromotionRedemption < ActiveRecord::Base
  belongs_to              :promotion, :counter_cache => :redemptions_count
  belongs_to              :redeemer, :polymorphic => true
  validates_presence_of   :promotion_id
  validates_presence_of   :redeemer
end