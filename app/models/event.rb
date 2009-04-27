class Event < ActiveRecord::Base
  validates_presence_of     :name, :event_venue_id, :source_type, :source_id
  validates_uniqueness_of   :source_id, :scope => :source_type
  belongs_to                :event_venue, :counter_cache => :events_count
end