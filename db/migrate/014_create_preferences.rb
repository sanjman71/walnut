class CreatePreferences < ActiveRecord::Migration
  def self.up
    create_table :preferences, :force => true do |t|
      t.string      :name,        :null => false
      t.string      :value,       :default => null
      t.integer     :ivalue,      :default => 0
      t.references  :preferable, :polymorphic => true
      t.timestamps
    end

    add_index :preferences, [:name]
  end
  
  def self.down
    drop_table :preferences  
  end
end
