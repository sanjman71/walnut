class AddCapacitySlotIndexes < ActiveRecord::Migration
  def self.up
    add_index :capacity_slots, :start_at
    add_index :capacity_slots, :end_at
    add_index :capacity_slots, :capacity
    add_index :capacity_slots, :duration
    add_index :capacity_slots, :company_id
    add_index :capacity_slots, :location_id
    add_index :capacity_slots, [:provider_id, :provider_type]
  end

  def self.down
    remove_index :capacity_slots, :start_at
    remove_index :capacity_slots, :end_at
    remove_index :capacity_slots, :capacity
    remove_index :capacity_slots, :duration
    remove_index :capacity_slots, :company_id
    remove_index :capacity_slots, :location_id
    remove_index :capacity_slots, [:provider_id, :provider_type]
  end
end
