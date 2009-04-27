class CreateEvents < ActiveRecord::Migration
  def self.up
    create_table :event_categories, :force => true do |t|
      t.string    :name,          :limit => 50, :null => false
      t.string    :source_type,   :limit => 20, :null => false
      t.string    :source_id,     :limit => 50, :null => false
      t.integer   :popularity,    :default => 0
    end
    
    add_index :event_categories, :name
    add_index :event_categories, :popularity
    add_index :event_categories, :source_id
    
    create_table :event_venues, :force => :true do |t|
      t.string      :name,          :null => false
      t.string      :city,          :limit => 50, :null => false
      t.string      :address
      t.string      :source_type,   :limit => 20, :null => false
      t.string      :source_id,     :limit => 50, :null => false
      t.integer     :events_count,  :default => 0
      t.references  :location
    end
    
    add_index :event_venues, :source_id
    add_index :event_venues, :location_id

    create_table :events, :force => :true do |t|
      t.string      :name,          :limit => 100, :null => false
      t.references  :event_venue
      t.string      :url,           :limit => 200
      t.datetime    :start_at
      t.datetime    :end_at
      t.string      :source_type,   :limit => 20, :null => false
      t.string      :source_id,     :limit => 50, :null => false
    end
    
    create_table :event_cities, :force => :true do |t|
      t.string  :name
    end
  end

  def self.down
    drop_table :event_categories
    drop_table :event_cities
    drop_table :event_venues
    drop_table :events
  end
end
