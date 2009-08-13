class GeoTagCount < ActiveRecord::Base
  belongs_to                :tag
  belongs_to                :geo, :polymorphic => true
  validates_presence_of     :tag_id, :taggings_count, :geo_id, :geo_type
  validates_uniqueness_of   :tag_id, :scope => [:geo_id, :geo_type]
end