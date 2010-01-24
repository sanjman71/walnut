class CreateCapacitySlot2s < ActiveRecord::Migration
  def self.up
    create_table :capacity_slot2s do |t|
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
    drop_table  :capacity_slot2s
  end
end
