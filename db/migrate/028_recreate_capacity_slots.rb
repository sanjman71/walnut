class RecreateCapacitySlots < ActiveRecord::Migration
  def self.up
    drop_table    :capacity_slots
    
    create_table  :capacity_slots do |t|
      t.references    :company
      t.references    :provider, :polymorphic => true
      t.references    :location
      t.datetime      :start_at
      t.datetime      :end_at
      t.integer       :duration
      t.integer       :capacity
    end
        
  end

  def self.down
    drop_table  :capacity_slots

    create_table "capacity_slots" do |t|
      t.integer  "free_appointment_id"
      t.datetime "start_at"
      t.datetime "end_at"
      t.integer  "duration"
      t.integer  "capacity"
      t.integer  "time_start_at"
      t.integer  "time_end_at"
      t.datetime "created_at"
      t.datetime "updated_at"
    end

  end
end
