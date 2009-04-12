class Neighborhood < ActiveRecord::Base
  validates_presence_of       :name, :city_id
  validates_uniqueness_of     :name, :scope => :city_id
  belongs_to                  :city, :counter_cache => true

  include NameParam

  # order neighborhoods by location count
  named_scope :order_by_density,      {:order => "locations_count DESC"}
end
