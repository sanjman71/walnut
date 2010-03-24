class AddLocationDeltaIndex < ActiveRecord::Migration
  def self.up
    add_index :locations, :delta
  end

  def self.down
    remove_index :locations, :delta
  end
end
