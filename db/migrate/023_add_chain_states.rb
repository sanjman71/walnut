class AddChainStates < ActiveRecord::Migration
  def self.up
    change_table :chains do |t|
      t.text :states
    end
  end

  def self.down
    remove_column :chains, :states
  end
end
