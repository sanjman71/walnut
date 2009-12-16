class AddCapacityToUsersResourcesServices < ActiveRecord::Migration
  def self.up
    change_table :users do |t|
      t.integer :capacity, :default => 1
    end
    change_table :resources do |t|
      t.integer :capacity, :default => 1
    end
    change_table :services do |t|
      t.integer :capacity, :default => 1
    end
  end

  def self.down
    remove_column :services, :capacity
    remove_column :resources, :capacity
    remove_column :users, :capacity
  end
end
