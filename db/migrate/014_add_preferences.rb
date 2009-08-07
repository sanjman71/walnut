class AddPreferences < ActiveRecord::Migration
  def self.up
    change_table :companies do |t|
      t.text :preferences
    end
    change_table :users do |t|
      t.text :preferences
    end
  end
  
  def self.down
    remove_column :companies, :preferences
    remove_column :users, :preferences
  end
end
