class AddCapacity_Slots < ActiveRecord::Migration
  def self.up
    create_table :capacity_slots do |t|
      t.references    :appointment
      t.datetime      :start_at
      t.datetime      :end_at
      t.integer       :duration
      t.integer       :capacity
    end

  end

  def self.down
    drop_table :capacity_slots
  end
end
