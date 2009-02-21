class PlaceTagGroup < ActiveRecord::Base
  belongs_to                :place
  belongs_to                :tag_group, :counter_cache => :places_count
  validates_uniqueness_of   :tag_group_id, :scope => :place_id
end