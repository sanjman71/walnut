class PlaceTagGroup < ActiveRecord::Base
  belongs_to                :place, :counter_cache => :tag_groups_count
  belongs_to                :tag_group, :counter_cache => :places_count
  validates_uniqueness_of   :tag_group_id, :scope => :place_id
end