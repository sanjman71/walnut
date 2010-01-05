class AddCompanyMessageDeliveries < ActiveRecord::Migration
  def self.up
    create_table :company_message_deliveries do |t|
      t.references :company
      t.references :message
      t.references :message_recipient
    end
    
    add_index :company_message_deliveries, :company_id
    add_index :company_message_deliveries, :message_id
    add_index :company_message_deliveries, :message_recipient_id
  end

  def self.down
    drop_table :company_message_deliveries
  end
end
