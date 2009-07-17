class CreateRecurrences < ActiveRecord::Migration
  def self.up
    create_table :recurrences do |t|
      t.references  :company
      t.references  :service
      t.references  :location
      t.references  :provider,            :polymorphic => true    # e.g. users
      t.references  :customer       # user who booked the appointment
      t.datetime    :start_at
      t.datetime    :end_at
      t.integer     :duration
      t.integer     :time_start_at  # time of day
      t.integer     :time_end_at    # time of day
      t.string      :mark_as
      t.string      :state
      t.string      :confirmation_code
      t.string      :uid              # The iCalendar UID
      t.text        :description
      t.datetime    :canceled_at
      t.boolean     :public,              :default => false

      t.string      :rrule            # iCalendar recurrence rule
      t.datetime    :expanded_to      # recurrence has been expanded up to this datetime (in UTC)
      t.integer     :remaining_count  # The count is added to the rrule, and needs to be decremented every time an appointment is instantiated
      t.datetime    :start_recurrence # The recurrence starts on or after before this datetime
      t.datetime    :end_recurrence   # The recurrence ends before this datetime

      t.string      :name,                :limit => 100
      t.integer     :popularity,          :default => 0
      t.string      :url,                 :limit => 200
      t.integer     :taggings_count,      :default => 0   # counter cache
      t.string      :source_type,         :limit => 20
      t.string      :source_id,           :limit => 50

      t.timestamps

    end
    
    change_table :locations do |t|
      t.integer :appointments_count, :default => 0
      t.string  :timezone
    end

  end
  
  def self.down
    remove_column :locations, :appointments_count
    remove_column :locations, :timezone

    drop_table :recurrences
  end
end
