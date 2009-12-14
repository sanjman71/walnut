class AddTimestampsToCapacitySlots < ActiveRecord::Migration
  def self.up
    add_timestamps(:capacity_slots)
  end

  def self.down
    remove_timestamps(:capacity_slots)
  end
end
