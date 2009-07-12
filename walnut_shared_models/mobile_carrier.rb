class MobileCarrier < ActiveRecord::Base
  validates_presence_of     :name, :key
  validates_uniqueness_of   :name
  validates_uniqueness_of   :key
end