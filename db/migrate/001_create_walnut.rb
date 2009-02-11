class CreateWalnut < ActiveRecord::Migration
  def self.up
    
    create_table :areas do |t|
      t.references  :extent, :polymorphic => true
      t.integer     :addresses_count, :default => 0  # counter cache of area addresses
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
  
    create_table :addresses do |t|
      t.string      :name
      t.string      :street_address,  :default => nil
      t.references  :city
      t.references  :state
      t.references  :zip
      t.references  :country
      t.references  :addressable, :polymorphic => true
    end
    
    # an address can have many addressables (e.g. places)
    # create_table :address_addressables do |t|
    #   t.references  :address
    #   t.references  :addressable, :polymorphic => true
    # end
    
    # an address can have many areas
    create_table :address_areas do |t|
      t.references  :area
      t.references  :address
    end
    
    create_table :places do |t|
      t.string      :name
      t.integer     :addresses_count, :default => 0   # counter cache
      t.references  :chain
    end

    create_table :chains do |t|
      t.string      :name
      t.integer     :places_count, :default => 0   # counter cache
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
