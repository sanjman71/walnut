class CreateLocatablesLocations < ActiveRecord::Migration
  def self.up

    # This file assumes that all of the location information has already been set up in the walnut database. So here we are simply adding to that database.
    create_table :peanut_locatables_locations do |t|
      t.references :location
      t.references :locatable, :polymorphic => true
    end

    add_index :peanut_locatables_locations, [:location_id]
    add_index :peanut_locatables_locations, [:locatable_id, :locatable_type], :name => "index_on_locatables"
    add_index :peanut_locatables_locations, [:location_id, :locatable_id, :locatable_type], :name => "index_on_locations_locatables"


  end

  def self.down
    drop_table :peanut_locatables_locations
  end
end
