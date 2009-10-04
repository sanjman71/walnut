class WaitlistTimeRange < ActiveRecord::Base
  belongs_to                  :waitlist

  validates_presence_of       :waitlist_id
  validates_presence_of       :start_date
  validates_presence_of       :end_date
  validates_presence_of       :start_time
  validates_presence_of       :end_time

  named_scope :past,          lambda { { :conditions => ["start_date < ?", Time.zone.now] } }

end