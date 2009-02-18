class Place < ActiveRecord::Base
  validates_presence_of     :name
  belongs_to                :chain, :counter_cache => true
  
  # TODO: find out why the counter cache field doesn't work without the before and after filters
  has_many                  :locations, :as => :locatable, :after_add => :after_add_location, :before_remove => :before_remove_location
  has_many                  :phone_numbers, :as => :callable, :after_add => :after_add_phone_number, :before_remove => :before_remove_phone_number

  has_many                  :states, :through => :locations
  has_many                  :cities, :through => :locations
  has_many                  :zips, :through => :locations
  
  acts_as_taggable_on       :tags
  
  private
  
  def after_add_location(location)
    Place.increment_counter(:locations_count, self.id) if location
  end
  
  def before_remove_location(location)
    Place.decrement_counter(:locations_count, self.id) if location
  end
  
  def after_add_phone_number(phone_number)
    Place.increment_counter(:phone_numbers_count, self.id) if phone_number
  end

  def before_remove_phone_number(phone_number)
    Place.decrement_counter(:phone_numbers_count, self.id) if phone_number
  end
  
end