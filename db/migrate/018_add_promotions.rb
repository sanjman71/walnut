class AddPromotions < ActiveRecord::Migration
  def self.up
    create_table :promotions do |t|
      t.string    :code, :limit => 50
      t.integer   :uses_allowed, :null => false
      t.integer   :redemptions_count, :default => 0 # counter cache
      t.string    :description
      t.float     :discount, :default => 0.0
      t.string    :units, :limit => 50 # e.g. percent, dollars
      t.float     :minimum, :default => 0.0
      t.datetime  :expires_at
      t.integer   :owner_id # polymorphic
      t.string    :owner_type, :limit => 50
    end

    add_index :promotions, :code
    add_index :promotions, [:owner_id, :owner_type]

    # track promotion redemptions
    create_table :promotion_redemptions do |t|
      t.references  :promotion
      t.integer     :redeemer_id # polymorphic
      t.string      :redeemer_type, :limit => 50
    end

    add_index :promotion_redemptions, :promotion_id
    add_index :promotion_redemptions, [:redeemer_id, :redeemer_type]
  end

  def self.down
    drop_table :promotions
    drop_table :promotion_redemptions
  end
end
