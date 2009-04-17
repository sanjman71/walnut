class CreateEvents < ActiveRecord::Migration
  def self.up
    create_table :eventful_categories, :force => true do |t|
      t.string    :name,          :null => false
      t.string    :eventful_id,   :null => false
    end
  end

  def self.down
  end
end
