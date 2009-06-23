class AddChainDisplayName < ActiveRecord::Migration
  def self.up
    add_column  :chains, :display_name, :string, :limit => 100
    
    add_index   :chains, :display_name
  end

  def self.down
    remove_column :chains, :display_name
  end
end
