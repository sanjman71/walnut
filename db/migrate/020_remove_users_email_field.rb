class RemoveUsersEmailField < ActiveRecord::Migration
  def self.up
    remove_column :users, :email
    remove_column :users, :identifier

    change_table :users do |t|
      t.integer :rpx, :default => 0
    end

    change_table :email_addresses do |t|
      t.string    :identifier, :limit => 150
      t.string    :state, :limit => 50
      t.string    :verification_code, :limit => 50
      t.datetime  :verification_sent_at
      t.datetime  :verified_at
      t.integer   :verification_failures, :default => 0
    end

    change_table :phone_numbers do |t|
      t.string  :state, :limit => 50
    end
  end

  def self.down
    change_table :users do |t|
      t.string  :email
      t.string  :identifier
    end

    remove_column :users, :rpx

    remove_column :email_addresses, :identifier
    remove_column :email_addresses, :state
    remove_column :email_addresses, :verification_code
    remove_column :email_addresses, :verification_sent_at
    remove_column :email_addresses, :verified_at
    remove_column :email_addresses, :verification_failures

    remove_column :phone_numbers, :state
  end
end
