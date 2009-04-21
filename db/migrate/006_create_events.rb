class CreateEvents < ActiveRecord::Migration
  def self.up
    create_table :eventful_categories, :force => true do |t|
      t.string    :name,          :limit => 50, :null => false
      t.string    :eventful_id,   :limit => 50, :null => false
      t.integer   :popularity,    :default => 0
    end
    
    add_index :eventful_categories, :eventful_id
    add_index :eventful_categories, :name
    add_index :eventful_categories, :popularity
    
    create_table :eventful_cities, :force => :true do |t|
      t.string  :name
    end

    create_table :eventful_venues, :force => :true do |t|
      t.string      :name,  :null => false
      t.string      :city,  :limit => 50, :null => false
      t.string      :address
      t.integer     :events_count, :default => 0
      t.references  :location
    end
    
    add_index :eventful_venues, :location_id
  end

  def self.down
    drop_table :eventful_categories
    drop_table :eventful_cities
    drop_table :eventful_venues
  end
end
