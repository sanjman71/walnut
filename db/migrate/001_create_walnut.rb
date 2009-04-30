class CreateWalnut < ActiveRecord::Migration
  def self.up
    
    create_table :countries do |t|
      t.string      :name,                  :limit => 30, :default => nil
      t.string      :code,                  :limit => 2, :default => nil
      t.integer     :locations_count,       :default => 0   # counter cache
    end

    add_index :countries, :code
    add_index :countries, :locations_count
    
    create_table :states do |t|
      t.string      :name,                  :limit => 30, :default => nil
      t.string      :code,                  :limit => 2, :default => nil
      t.references  :country
      t.decimal     :lat,                   :precision => 15, :scale => 10
      t.decimal     :lng,                   :precision => 15, :scale => 10
      t.integer     :cities_count,          :default => 0   # counter cache
      t.integer     :zips_count,            :default => 0   # counter cache
      t.integer     :locations_count,       :default => 0   # counter cache
      t.integer     :events,                :default => 0
    end

    add_index :states, :country_id
    add_index :states, [:country_id, :locations_count]
    add_index :states, [:country_id, :code]

    create_table :cities do |t|
      t.string      :name,                  :limit => 30, :default => nil
      t.references  :state
      t.decimal     :lat,                   :precision => 15, :scale => 10
      t.decimal     :lng,                   :precision => 15, :scale => 10
      t.integer     :neighborhoods_count,   :default => 0   # counter cache
      t.integer     :locations_count,       :default => 0   # counter cache
    end

    add_index :cities, :state_id
    add_index :cities, :locations_count
    add_index :cities, [:state_id, :locations_count], :name => "index_cities_on_state_and_locations"
    
    create_table :zips do |t|
      t.string      :name,                  :limit => 10, :default => nil
      t.references  :state
      t.decimal     :lat,                   :precision => 15, :scale => 10
      t.decimal     :lng,                   :precision => 15, :scale => 10
      t.integer     :locations_count,       :default => 0   # counter cache
    end

    add_index :zips, :state_id
    add_index :zips, [:state_id, :locations_count]

    create_table :neighborhoods do |t|
      t.string      :name,                  :limit => 30, :default => nil
      t.references  :city
      t.decimal     :lat,                   :precision => 15, :scale => 10
      t.decimal     :lng,                   :precision => 15, :scale => 10
      t.integer     :locations_count,       :default => 0   # counter cache
    end
    
    add_index :neighborhoods, :city_id, :name => "index_hoods_on_city"
    add_index :neighborhoods, :locations_count, :name => "index_hoods_on_locations"
    add_index :neighborhoods, [:city_id, :locations_count], :name => "index_hoods_on_city_and_locations"
    
    create_table :location_neighborhoods do |t|
      t.references  :location
      t.references  :neighborhood
    end
    
    add_index :location_neighborhoods, :location_id, :name => "index_ln_on_locations"
    add_index :location_neighborhoods, :neighborhood_id, :name => "index_ln_on_neighborhoods"
    
    create_table :locations do |t|
      t.string      :name,                  :limit => 30
      t.string      :street_address,        :default => nil
      t.references  :city
      t.references  :state
      t.references  :zip
      t.references  :country
      t.integer     :neighborhoods_count,   :default => 0 # counter cache
      t.decimal     :lat,                   :precision => 15, :scale => 10
      t.decimal     :lng,                   :precision => 15, :scale => 10
      t.references  :source,                :polymorphic => true, :default => nil
      t.integer     :popularity,            :default => 0 # used to order search results
      t.integer     :recommendations_count, :default => 0
      t.integer     :events_count,          :default => 0
      t.integer     :status,                :default => 0
      t.boolean     :delta  # used by sphinx for real-time indexing
    end
            
    add_index :locations, [:source_id, :source_type], :name => "index_locations_on_source"
    add_index :locations, [:popularity]
    add_index :locations, [:recommendations_count]
    add_index :locations, [:city_id], :name => "index_locations_on_city"
    
    create_table :phone_numbers do |t|
      t.string      :name,      :limit => 20
      t.string      :number,    :limit => 20, :default => nil
      t.references  :callable,  :limit => 20, :polymorphic => true
    end

    add_index :phone_numbers, [:callable_id, :callable_type], :name => "index_phone_numbers_on_callable"
    
    create_table :places do |t|
      t.string      :name,                  :limit => 50
      t.integer     :locations_count,       :default => 0   # counter cache
      t.integer     :phone_numbers_count,   :default => 0   # counter cache
      t.references  :chain
      t.integer     :tag_groups_count,      :default => 0   # counter cache
    end

    create_table :location_places do |t|
      t.references  :location
      t.references  :place
    end

    add_index :location_places, :location_id
    add_index :location_places, :place_id

    create_table :chains do |t|
      t.string      :name
      t.integer     :places_count,          :default => 0   # counter cache
    end

    add_index :chains, :places_count
  end

  def self.down
    drop_table  :countries
    drop_table  :states
    drop_table  :cities
    drop_table  :zips
    drop_table  :neighborhoods
    drop_table  :city_zips
    drop_table  :locations
    drop_table  :places
    drop_table  :chains
  end
end
