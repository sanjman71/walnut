class Neighborhood < ActiveRecord::Base
  validates_presence_of       :name, :city_id
  validates_uniqueness_of     :name, :scope => :city_id
  belongs_to                  :city, :counter_cache => true
  has_many                    :location_neighborhoods
  has_many                    :locations, :through => :location_neighborhoods
  
  include NameParam

  # find neighborhoods with locations
  named_scope :with_locations,        { :conditions => ["locations_count > 0"] }

  # order neighborhoods by location count
  named_scope :order_by_density,      {:order => "locations_count DESC"}
end
