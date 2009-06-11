class Place < ActiveRecord::Base
  validates_presence_of     :name
  belongs_to                :chain, :counter_cache => true
  
  has_many                  :location_places
  has_many                  :locations, :through => :location_places, :after_add => :after_add_location, :after_remove => :after_remove_location

  has_many                  :phone_numbers, :as => :callable

  has_many                  :place_tag_groups
  has_many                  :tag_groups, :through => :place_tag_groups

  has_many                  :states, :through => :locations
  has_many                  :cities, :through => :locations
  has_many                  :zips, :through => :locations
  
  acts_as_taggable_on       :tags
  
  named_scope :with_locations,      { :conditions => ["locations_count > 0"] }
  named_scope :with_chain,          { :conditions => ["chain_id is NOT NULL"] }
  named_scope :no_chain,            { :conditions => ["chain_id is NULL"] }
  named_scope :with_tag_groups,     { :conditions => ["tag_groups_count > 0"] }
  named_scope :no_tag_groups,       { :conditions => ["tag_groups_count = 0"] }
  
  def primary_phone_number
    return nil if phone_numbers_count == 0
    phone_numbers.first
  end

  def chain?
    !self.chain_id.blank?
  end
  
  private
  
  def after_add_location(location)
    return if location.blank?

    # Note: incrementing the counter cache is done using built-in activerecord callback
  end
  
  def after_remove_location(location)
    return if location.blank?

    # decrement locations_count counter cache
    # TODO: find out why the built-in counter cache doesn't work here
    Place.decrement_counter(:locations_count, id)
  end
  
end