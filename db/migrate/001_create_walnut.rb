class CreateWalnut < ActiveRecord::Migration
  def self.up
    
    # Geo objects
    
    create_table :areas do |t|
      t.references  :extent, :polymorphic => true
    end

    create_table :countries do |t|
      t.string      :name,          :default => nil
      t.string      :code,          :default => nil
    end

    create_table :states do |t|
      t.string      :name,          :default => nil
      t.string      :code,          :default => nil
      t.references  :country
    end

    create_table :cities do |t|
      t.string      :name,          :default => nil
      t.references  :state
    end

    create_table :zips do |t|
      t.string      :name,          :default => nil
      t.references  :state
    end

    create_table :neighborhoods do |t|
      t.string      :name,          :default => nil
      t.references  :city
      t.references  :state
    end
    
    create_table :city_zips do |t|
      t.references  :city
      t.references  :zip
    end

    create_table :city_neighborhoods do |t|
      t.references  :city
      t.references  :neighborhood
    end
  
    create_table :addresses do |t|
      t.string      :name
      t.string      :street_address
      t.string      :city
      t.string      :state
      t.string      :zip
      t.string      :country
    end
    
    # An address can have many addressables (e.g. places)
    create_table :address_addressables do |t|
      t.references  :address
      t.references  :addressable, :polymorphic => true
    end
    
    # An address can have many areas
    create_table :address_areas do |t|
      t.references  :area
      t.references  :address
    end
    
    create_table :places do |t|
      t.string      :name
      t.integer     :addresses_count
    end
  end

  def self.down
    drop_table  :areas
    drop_table  :states
    drop_table  :cities
    drop_table  :zips
    drop_table  :neighborhoods
    drop_table  :addresses
    drop_table  :address_areas
  end
end
