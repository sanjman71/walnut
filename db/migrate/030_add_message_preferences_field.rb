class AddMessagePreferencesField < ActiveRecord::Migration
  def self.up
    change_table :messages do |t|
      t.text :preferences
    end
  end

  def self.down
    remove_column :messages, :preferences
  end
end
