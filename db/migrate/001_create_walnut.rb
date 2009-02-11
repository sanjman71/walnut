class CreateWalnut < ActiveRecord::Migration
  def self.up
    
    create_table :localities do |t|
      t.references  :extent, :polymorphic => true
      t.integer     :locations_count, :default => 0  # counter cache of locations
    end

    create_table :countries do |t|
      t.string      :name,          :default => nil
      t.string      :code,          :default => nil
    end

    create_table :states do |t|
      t.string      :name,          :default => nil
      t.string      :code,          :default => nil
      t.references  :country
      t.integer     :cities_count,  :default => 0
      t.integer     :zips_count,    :default => 0
    end

    create_table :cities do |t|
      t.string      :name,          :default => nil
      t.references  :state
      t.integer     :neighborhoods_count, :default => 0
    end

    create_table :zips do |t|
      t.string      :name,          :default => nil
      t.references  :state
    end

    create_table :neighborhoods do |t|
      t.string      :name,          :default => nil
      t.references  :city
    end
    
    create_table :city_zips do |t|
      t.references  :city
      t.references  :zip
    end
  
    create_table :locations do |t|
      t.string      :name
      t.string      :street_address,  :default => nil
      t.references  :city
      t.references  :state
      t.references  :zip
      t.references  :country
      t.references  :locatable, :polymorphic => true
    end
        
    # many to many relationship between locations and localities
    create_table :locality_locations do |t|
      t.references  :locality
      t.references  :location
    end
    
    create_table :places do |t|
      t.string      :name
      t.integer     :locations_count, :default => 0   # counter cache
      t.references  :chain
    end

    create_table :chains do |t|
      t.string      :name
      t.integer     :places_count, :default => 0   # counter cache
    end
  end

  def self.down
    drop_table  :states
    drop_table  :cities
    drop_table  :zips
    drop_table  :neighborhoods
    drop_table  :locations
    drop_table  :localities
    drop_table  :locality_locations
  end
end
