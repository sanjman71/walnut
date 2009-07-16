class CreateRecurrences < ActiveRecord::Migration
  def self.up
    create_table :recurrences do |t|
      t.references  :company
      t.references  :service
      t.references  :provider, :polymorphic => true    # e.g. users
      t.references  :customer       # user who booked the appointment
      t.references  :location
      t.datetime    :start_at
      t.datetime    :end_at
      t.integer     :duration
      t.integer     :time_start_at  # time of day
      t.integer     :time_end_at    # time of day
      t.string      :mark_as
      t.string      :state
      t.string      :confirmation_code
      t.datetime    :canceled_at
      t.text        :description
      t.string      :rrule            # iCalendar recurrence rule
      t.datetime    :expanded_to      # recurrence has been expanded up to this datetime (in UTC)
      t.integer     :remaining_count  # The count is added to the rrule, and needs to be decremented every time an appointment is instantiated
      t.datetime    :end_recurrence   # The recurrence ends before this datetime
      t.timestamps
    end
    
  end
  
  def self.down
    drop_table :recurrences
  end
end
