class LocatablesLocation < ActiveRecord::Base
  belongs_to :location
  belongs_to :locatable, :polymorphic => true, :counter_cache => :locations_count
end
