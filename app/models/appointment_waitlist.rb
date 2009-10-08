class AppointmentWaitlist < ActiveRecord::Base
  belongs_to              :appointment, :counter_cache => :appointment_waitlists_count
  belongs_to              :waitlist, :counter_cache => :appointment_waitlists_count
  validates_presence_of   :appointment_id
  validates_presence_of   :waitlist_id
  validates_uniqueness_of :waitlist_id, :scope => :appointment_id
  
  def self.create_waitlist(o)
    appointment_waitlists = []

    case o.class.to_s.downcase
    when 'appointment'
      o.waitlist.each do |w|
        aw = o.appointment_waitlists.find_by_waitlist_id(w.id) || o.appointment_waitlists.create(:waitlist => w)
        appointment_waitlists.push(aw)
      end
    when 'waitlist'
      o.available_free_time.each do |appointment|
        aw = appointment.appointment_waitlists.find_by_waitlist_id(o.id) || appointment.appointment_waitlists.create(:waitlist => o)
        appointment_waitlists.push(aw)
      end
    end

    appointment_waitlists
  end
end