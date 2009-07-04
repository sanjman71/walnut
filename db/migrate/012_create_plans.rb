class CreatePlans < ActiveRecord::Migration
  def self.up
    
    create_table :peanut_plans do |t|
      t.string      :name
      t.boolean     :enabled
      t.string      :icon
      t.integer     :cost   # value in cents
      t.string      :cost_currency
      t.integer     :max_locations
      t.integer     :max_providers
      t.integer     :start_billing_in_time_amount   # e.g. 1, 5, 30
      t.string      :start_billing_in_time_unit     # e.g. days, months
      t.integer     :between_billing_time_amount    # e.g. 1, 5, 30
      t.string      :between_billing_time_unit      # e.g. days, months

      t.timestamps
    end
    
  end

  def self.down
    drop_table :peanut_plans
  end
end
