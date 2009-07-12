class AddBotStats < ActiveRecord::Migration
  def self.up
    create_table :bot_stats do |t|
      t.string      :name, :limit => 50
      t.datetime    :date
      t.integer     :count
    end
    
    add_index :bot_stats, :name
    add_index :bot_stats, [:name, :date]
  end

  def self.down
    drop_table :bot_stats
  end
end
