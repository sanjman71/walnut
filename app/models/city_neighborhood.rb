class CityNeighborhood < ActiveRecord::Base
  belongs_to                :city
  belongs_to                :neighborhood
  validates_uniqueness_of   :neighborhood_id, :scope => :city_id
end