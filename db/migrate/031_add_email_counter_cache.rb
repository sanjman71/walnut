class AddEmailCounterCache < ActiveRecord::Migration
  def self.up
    change_table :locations do |t|
      t.integer :email_addresses_count, :default => 0
    end

    change_table :companies do |t|
      t.integer :email_addresses_count, :default => 0
    end
  end

  def self.down
    remove_column :locations, :email_addresses_count
    remove_column :companies, :email_addresses_count
  end
end
