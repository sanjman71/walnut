class AppointmentEventCategory < ActiveRecord::Base
  validates_presence_of     :appointment_id, :event_category_id
  validates_uniqueness_of   :appointment_id, :scope => :event_category_id
  belongs_to                :appointment
  belongs_to                :event_category   # handle counter cache in event model
end