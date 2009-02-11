class Place < ActiveRecord::Base
  validates_presence_of     :name
  validates_uniqueness_of   :name
  belongs_to                :chain, :counter_cache => true
  
  # TODO: find out why the counter cache field doesn't work without the before and after filters
  has_many                  :addresses, :as => :addressable, :after_add => :after_add_address, :before_remove => :before_remove_address
  
  has_many                  :states, :through => :addresses
  has_many                  :cities, :through => :addresses
  has_many                  :zips, :through => :addresses
  
  attr_readonly             :addresses_count
  
  # acts_as_taggable_on       :tags
  
  private
  
  def after_add_address(address)
    Place.increment_counter(:addresses_count, self.id) if address
  end
  
  def before_remove_address(address)
    Place.decrement_counter(:addresses_count, self.id) if address
  end
end