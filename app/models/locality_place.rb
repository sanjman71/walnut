class LocalityPlace < ActiveRecord::Base
  belongs_to                :locality, :polymorphic => true
  belongs_to                :place
  validates_uniqueness_of   :place_id, :scope => [:locality_id, :locality_type]
end