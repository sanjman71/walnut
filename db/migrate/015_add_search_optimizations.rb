class AddSearchOptimizations < ActiveRecord::Migration
  def self.up
    create_table :geo_tag_counts do |t|
      t.integer     :geo_id   # polymorphic type, with a string limit
      t.string      :geo_type, :limit => 50
      t.references  :tag
      t.integer     :taggings_count
    end
    
    add_index :geo_tag_counts, [:geo_id, :geo_type]
    add_index :geo_tag_counts, :taggings_count
    
    create_table :city_zips do |t|
      t.references  :city
      t.references  :zip
    end
    
    add_index :city_zips, :city_id
    add_index :city_zips, :zip_id
    
    change_table :cities do |t|
      t.integer   :events_count, :default => 0
      t.integer   :tags_count, :default => 0
    end

    add_index :cities, :events_count
    add_index :cities, :tags_count
    add_index :cities, :neighborhoods_count # add missing index

    change_table :neighborhoods do |t|
      t.integer   :events_count, :default => 0
      t.integer   :tags_count, :default => 0
    end
    
    add_index :neighborhoods, :events_count
    add_index :neighborhoods, :tags_count

    change_table :zips do |t|
      t.integer   :events_count, :default => 0
      t.integer   :tags_count, :default => 0
    end

    add_index :zips, :events_count
    add_index :zips, :tags_count
    
    add_index :states, [:country_id, :name]  # add missing states table index
  end

  def self.down
    drop_table :geo_tag_counts
    drop_table :city_zips
    
    remove_column :cities, :events_count
    remove_column :cities, :tags_count
    remove_index  :cities, :neighborhoods_count
    remove_column :neighborhoods, :events_count
    remove_column :neighborhoods, :tags_count
    remove_column :zips, :events_count
    remove_column :zips, :tags_count
    remove_index  :states, [:country_id, :name]
  end
end
