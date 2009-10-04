class AddWaitlist < ActiveRecord::Migration
  def self.up
    create_table :waitlists do |t|
      t.references  :company
      t.references  :service
      t.references  :location
      t.references  :provider,  :polymorphic => true    # e.g. users
      t.references  :customer             # user who booked the waitlist
      t.references  :creator              # user who created the waitlist
      t.timestamps
    end

    add_index :waitlists, :company_id
    add_index :waitlists, [:provider_id, :provider_type]
    add_index :waitlists, :location_id
    add_index :waitlists, :service_id
    add_index :waitlists, :customer_id
    add_index :waitlists, :creator_id
    
    create_table :waitlist_time_ranges do |t|
      t.references  :waitlist
      t.datetime    :start_date
      t.datetime    :end_date
      t.integer     :start_time   # time of day to start
      t.integer     :end_time     # time of day to end
      t.timestamps
    end
  end

  def self.down
    drop_table :waitlists
    drop_table :waitlist_time_ranges
  end
end
