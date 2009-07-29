class AddCapacitySlots < ActiveRecord::Migration
  def self.up
    create_table :capacity_slots do |t|
      t.references    :free_appointment, :class_name => "Appointment", :default => nil
      t.datetime      :start_at
      t.datetime      :end_at
      t.integer       :duration         # duration of the slot. This is measured in minutes
      t.integer       :capacity
      t.integer       :time_start_at    # for time of day searches. These are measured in seconds
      t.integer       :time_end_at
    end

    change_table :appointments do |t|
      t.integer       :capacity, :default => 1          # Capacity available for free appointments, or used by work appointments. By default this is 1
      t.references    :free_appointment, :class_name => "Appointment", :default => nil # Free appointment corresponding to work appointments.
    end
  end

  def self.down
    remove_column :appointments, :capacity
    remove_column :appointments, :free_appointment_id
    drop_table :capacity_slots    
  end
end
