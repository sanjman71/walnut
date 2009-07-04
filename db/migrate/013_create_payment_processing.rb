class CreatePaymentProcessing < ActiveRecord::Migration
  def self.up
    create_table :peanut_payments do |t|
      t.references  :subscription
      t.string      :description 
      t.integer     :amount
      t.string      :state, :default => 'pending'
      t.boolean     :success 
      t.string      :reference 
      t.string      :message 
      t.string      :action 
      t.text        :params 
      t.boolean     :test
      t.timestamps
    end  
    
    create_table :peanut_subscriptions do |t|
      t.references  :user
      t.references  :company
      t.references  :plan
      t.datetime    :start_billing_at
      t.datetime    :last_billing_at
      t.datetime    :next_billing_at
      t.integer     :paid_count, :default => 0
      t.integer     :billing_errors_count, :default => 0
      t.string      :vault_id, :default => nil
      t.string      :state, :default => 'initialized'
      t.timestamps
    end
  end

  def self.down
    drop_table  :peanut_payments
    drop_table  :peanut_subscriptions
  end
end
