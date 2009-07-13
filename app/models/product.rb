class Product < ActiveRecord::Base
  belongs_to                :company
  validates_presence_of     :company_id, :name, :inventory, :price_in_cents
  validates_uniqueness_of   :name, :scope => :company_id

  # products with inventory > 0
  named_scope :instock,         { :conditions => ["inventory > 0"] }

  # products with inventory == 0
  named_scope :outofstock,      { :conditions => ["inventory = 0"] }
  
  
  # return true if the there is at least 1 of this product
  def stocked?
    return self.inventory > 0
  end
  
  def inventory_add!(i)
    self.inventory += i
    self.save
  end
  
  def inventory_remove!(i)
    self.inventory -= i
    self.save
  end
  
end