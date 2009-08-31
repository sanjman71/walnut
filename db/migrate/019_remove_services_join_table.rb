class RemoveServicesJoinTable < ActiveRecord::Migration
  def self.up
    # service belongs to one company
    change_table :services do |t|
      t.references  :company
    end
    
    # join table no longer used
    drop_table :company_services

    remove_column :users, :mobile_carrier_id
    remove_column :users, :phone
  end

  def self.down
    remove_column :services, :company_id
    create_table  :company_services

    add_column    :users, :mobile_carrier_id
    add_column    :users, :phone
  end
end
