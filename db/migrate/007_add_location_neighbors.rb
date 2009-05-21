class AddLocationNeighbors < ActiveRecord::Migration
  def self.up
    create_table :location_neighbors do |t|
      t.references    :location, :null => false
      t.integer       :neighbor_id, :null => false
      t.decimal       :distance, :precision => 15, :scale => 10
    end
    
    add_index :location_neighbors, :location_id
    add_index :location_neighbors, :neighbor_id
    add_index :location_neighbors, [:location_id, :neighbor_id], :unique => true
  end

  def self.down
    drop_table :location_neighbors
  end
end
