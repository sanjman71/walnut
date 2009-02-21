class AddTagGroups < ActiveRecord::Migration
  def self.up
    create_table :tag_groups do |t|
      t.string    :name,  :null => false
      t.text      :tags, :default => nil
      t.text      :recent_add_tags, :default => nil
      t.text      :recent_remove_tags, :default => nil
      t.integer   :places_count, :default => 0    # counter cache
    end
    
    add_index :tag_groups, [:name]
    
    create_table :place_tag_groups do |t|
      t.references  :tag_group
      t.references  :place
    end
  end

  def self.down
    drop_table  :tag_groups
    drop_table  :place_tag_groups
  end
end
