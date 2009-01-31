class Area < ActiveRecord::Base
  belongs_to                :extent, :polymorphic => true
  validates_presence_of     :extent_id, :extent_type
  validates_uniqueness_of   :extent_id, :scope => :extent_type

  acts_as_mappable
  
  def self.resolve(s)
    
  end
  
end