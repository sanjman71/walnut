class EventCategoryMapping < ActiveRecord::Base
  validates_presence_of     :event_id, :event_category_id
  validates_uniqueness_of   :event_id, :scope => :event_category_id
  belongs_to                :event
  belongs_to                :event_category
end