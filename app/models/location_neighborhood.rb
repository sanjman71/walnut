class LocationNeighborhood < ActiveRecord::Base
  validates_presence_of     :location_id, :neighborhood_id
  validates_uniqueness_of   :neighborhood_id, :scope => :location_id
  belongs_to                :location, :counter_cache => :neighborhoods_count
  belongs_to                :neighborhood, :counter_cache => :locations_count
end