class AddTimezones < ActiveRecord::Migration
  def self.up
    create_table :timezones do |t|
      t.string    :name, :limit => 100, :null => false
      t.integer   :utc_offset, :null => false
      t.integer   :utc_dst_offset, :null => false
      t.string    :rails_time_zone_name, :limit => 100
    end

    change_table :locations do |t|
      t.references :timezone
    end

    add_index :locations, :timezone_id

    change_table :companies do |t|
      t.references :timezone
    end

    add_index :companies, :timezone_id

    change_table :cities do |t|
      t.references :timezone
    end

    add_index :cities, :timezone_id

    change_table :zips do |t|
      t.references :timezone
    end

    add_index :zips, :timezone_id
  end

  def self.down
    remove_column :locations, :timezone_id
    remove_column :companies, :timezone_id
    remove_column :cities, :timezone_id
    remove_column :zips, :timezone_id
    
    drop_table :timezones
  end
end
