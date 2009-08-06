class CreatePreferences < ActiveRecord::Migration
  def self.up
    create_table :preferences, :force => true do |t|
      t.string      :name,        :null => false
      t.string      :value,       :default => nil
      t.integer     :ivalue,      :default => 0
      t.boolean     :bvalue,      :default => false
      t.timestamp   :tvalue,      :default => nil
      t.references  :preferable, :polymorphic => true
      t.timestamps
    end

    add_index :preferences, [:name]
  end
  
  def self.down
    drop_table :preferences  
  end
end
