class CreateEvents < ActiveRecord::Migration
  def self.up
    create_table :eventful_categories, :force => true do |t|
      t.string    :name,          :limit => 50, :null => false
      t.string    :eventful_id,   :limit => 50, :null => false
      t.integer   :popularity,    :default => 0
    end
    
    add_index :eventful_categories, :eventful_id
    add_index :eventful_categories, :name
    add_index :eventful_categories, :popularity
    
    create_table :eventful_cities, :force => :true do |t|
      t.string  :name
    end
  end

  def self.down
    drop_table :eventful_categories
  end
end
