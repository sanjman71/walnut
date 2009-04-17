class CreateEvents < ActiveRecord::Migration
  def self.up
    create_table :eventful_categories, :force => true do |t|
      t.string    :name,          :null => false
      t.string    :eventful_id,   :null => false
      t.integer   :popularity,    :default => 0
    end
    
    add_index :eventful_categories, :eventful_id
    
    create_table :eventful_cities, :force => :true do |t|
      t.string  :name
    end
    
    # create cities
    ["Chicago", "Charlotte", "New York", "Philadelphia"].each do |s|
      EventfulFeed::City.create(:name => s)
    end
  end

  def self.down
    drop_table :eventful_categories
  end
end
