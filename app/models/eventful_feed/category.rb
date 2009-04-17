module EventfulFeed

  class Category < ActiveRecord::Base
    set_table_name "eventful_categories"
    validates_presence_of     :name
    validates_presence_of     :eventful_id
    validates_uniqueness_of   :eventful_id
    
    named_scope :popular,         { :conditions => ["popularity > 0"] }
    named_scope :order_by_name,   { :order => "name ASC" }
  end
  
end