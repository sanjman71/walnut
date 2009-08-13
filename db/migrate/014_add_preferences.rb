class AddPreferences < ActiveRecord::Migration
  def self.up
    change_table :locations do |t|
      t.text :preferences
    end
    change_table :companies do |t|
      t.text :preferences
    end
    change_table :appointments do |t|
      t.text :preferences
    end
    change_table :users do |t|
      t.text :preferences
    end
    change_table :resources do |t|
      t.text :preferences
    end
    change_table :services do |t|
      t.text :preferences
    end
  end
  
  def self.down
    remove_column :services, :preferences
    remove_column :resources, :preferences
    remove_column :users, :preferences
    remove_column :appointments, :preferences
    remove_column :companies, :preferences
    remove_column :locations, :preferences
  end
end
