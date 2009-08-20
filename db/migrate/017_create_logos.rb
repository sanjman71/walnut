class CreateLogos < ActiveRecord::Migration
  def self.up
    create_table :logos, :force => true do |t|
      t.string     :image_file_name
      t.string     :image_content_type
      t.integer    :image_file_size
      t.datetime   :image_updated_at
      t.references :company
      t.timestamps
    end
    
    add_index :logos, :company_id, :unique => true

  end
  
  def self.down
    drop_table :logos
  end
  
end
