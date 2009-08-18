class AddMessages < ActiveRecord::Migration
  def self.up
    create_table :messages do |t|
      t.integer   :sender_id  # user
      t.string    :subject, :limit => 200
      t.text      :body
      t.integer   :priority, :default => 0
      t.datetime  :send_at  # time to send message at
      t.timestamps
    end
    
    add_index :messages, :sender_id
    
    create_table :message_recipients do |t|
      t.references  :message
      t.references  :messagable, :polymorphic => true
      t.string      :protocol   # e.g. email, sms, im, local
      t.string      :state, :limit => 50
      t.datetime    :sent_at
      t.timestamps
    end
    
    add_index :message_recipients, :message_id
    add_index :message_recipients, :protocol
    add_index :message_recipients, :state
    add_index :message_recipients, :sent_at
    
    create_table :message_threads do |t|
      t.references  :message
      t.string      :thread, :limit => 100
      t.timestamps
    end
    
    add_index :message_threads, :message_id
    add_index :message_threads, :thread
    
    create_table :email_addresses do |t|
      t.integer   :emailable_id   # polymorphic
      t.string    :emailable_type, :limit => 50
      t.string    :address, :limit => 100
      t.string    :email, :limit => 100
      t.integer   :priority, :default => 1
    end
    
    add_index :email_addresses, :emailable_type
    add_index :email_addresses, [:emailable_id, :emailable_type]
    add_index :email_addresses, [:emailable_id, :emailable_type, :priority], :name => "index_email_on_emailable_and_priority"
    add_index :email_addresses, :email
    
    change_table :users do |t|
      t.integer :phone_numbers_count, :default => 0
      t.integer :email_addresses_count, :default => 0
    end

    change_table :phone_numbers do |t|
      t.rename  :number, :address
      t.integer :priority, :default => 1
    end
    
    add_index :phone_numbers, :callable_type
    add_index :phone_numbers, [:callable_type, :callable_id, :priority], :name => "index_phone_on_callable_and_priority"
  end

  def self.down
    drop_table :messages
    drop_table :message_recipients
    drop_table :message_threads
    drop_table :email_addresses
    
    remove_column :users, :phone_numbers_count
    remove_column :users, :email_addresses_count

    change_table :phone_numbers do |t|
      t.rename  :address, :number
    end

    remove_column :phone_numbers, :priority
    remove_index  :phone_numbers, :callable_type
  end
end
