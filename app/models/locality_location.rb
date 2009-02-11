class LocalityLocation < ActiveRecord::Base
  belongs_to              :locality, :counter_cache => :locations_count
  belongs_to              :location
  validates_presence_of   :locality_id, :location_id
end