class LocationPlace < ActiveRecord::Base
  validates_presence_of     :location_id, :place_id
  validates_uniqueness_of   :place_id, :scope => :location_id
  belongs_to                :place, :counter_cache => :locations_count
  belongs_to                :location
end