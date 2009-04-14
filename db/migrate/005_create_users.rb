class CreateUsers < ActiveRecord::Migration
  def self.up
    create_table :users, :force => true do |t|
      t.string    :name,                      :limit => 100, :default => '', :null => true
      t.string    :email,                     :limit => 100
      t.string    :phone,                     :limit => 40
      t.integer   :mobile_carrier_id
      t.string    :crypted_password,          :limit => 40
      t.string    :salt,                      :limit => 40
      t.datetime  :created_at
      t.datetime  :updated_at
      t.string    :remember_token,            :limit => 40
      t.datetime  :remember_token_expires_at
      t.string    :activation_code,           :limit => 40
      t.datetime  :activated_at
      t.string    :state,                     :null => :no, :default => 'passive'
      t.datetime  :deleted_at
      t.integer   :invitation_id
      t.integer   :invitation_limit
    end
    
    add_index :users, [:email], :unique => true
    
    create_table :invitations do |t|
      t.integer   :sender_id
      t.integer   :recipient_id
      t.string    :recipient_email
      t.string    :token
      t.datetime  :sent_at
      t.integer   :company_id
      
      t.timestamps
    end
  end

  def self.down
    drop_table :users
  end
end
