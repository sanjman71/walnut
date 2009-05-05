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
    end
    
    add_index :users, :email, :unique => true
    add_index :users, :name

    create_table :mobile_carriers do |t|
      t.string :name
      t.string :key   # used by SMSFu plugin to find carrier's email gateway address
    end

    add_index :mobile_carriers, :name
    add_index :mobile_carriers, :key

    # Create default mobile carriers
    MobileCarrier.create(:name => 'Alltel Wireless',    :key => 'alltel')
    MobileCarrier.create(:name => 'AT&T/Cingular',      :key => 'at&t')
    MobileCarrier.create(:name => 'Boost Mobile',       :key => 'boost')
    MobileCarrier.create(:name => 'Sprint Wireless',    :key => 'sprint')
    MobileCarrier.create(:name => 'T-Mobile US',        :key => 't-mobile')
    MobileCarrier.create(:name => 'T-Mobile UK',        :key => 't-mobile-uk')
    MobileCarrier.create(:name => 'Virgin Mobile',      :key => 'virgin')
    MobileCarrier.create(:name => 'Verizon Wireless',   :key => 'verizon')
  end

  def self.down
    drop_table :users
    drop_table :mobile_carriers
  end
end
