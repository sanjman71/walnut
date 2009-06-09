class Event < ActiveRecord::Base
  validates_presence_of     :name

  belongs_to                :location # counter cache implemented manually with a callback; the counter_cache didn't work for event adds
  
  has_many                  :event_category_mappings, :dependent => :destroy
  has_many                  :event_categories, :through => :event_category_mappings, :after_add => :after_add_category, :after_remove => :after_remove_category
  
  before_destroy            :before_destroy_callback

  acts_as_taggable_on       :event_tags

  delegate                  :country, :to => '(location or return nil)'
  delegate                  :state, :to => '(location or return nil)'
  delegate                  :city, :to => '(location or return nil)'
  delegate                  :zip, :to => '(location or return nil)'
  delegate                  :neighborhoods, :to => '(location or return nil)'
  delegate                  :street_address, :to => '(location or return nil)'
  delegate                  :lat, :to => '(location or return nil)'
  delegate                  :lng, :to => '(location or return nil)'

  # find appointments based on a named time range, use lambda to ensure time value is evaluated at run-time
  named_scope :future,      lambda { { :conditions => ["start_at >= ?", Time.now.beginning_of_day.utc] } }
  named_scope :past,        lambda { { :conditions => ["start_at < ?", Time.now.beginning_of_day.utc - 1.day] } } # be conservative

  named_scope :min_popularity,  lambda { |x| {:conditions => ["popularity >= ?", x] }}

  define_index do
    indexes name, :as => :name
    indexes location.street_address, :as => :address
    has start_at, :as => :start_at
    has popularity, :type => :integer, :as => :popularity
    has location_id, :type => :integer, :as => :events, :facet => true
    # locality attributes, all faceted
    has location.country_id, :type => :integer, :as => :country_id, :facet => true
    has location.state_id, :type => :integer, :as => :state_id, :facet => true
    has location.city_id, :type => :integer, :as => :city_id, :facet => true
    has location.zip_id, :type => :integer, :as => :zip_id, :facet => true
    has location.neighborhoods(:id), :as => :neighborhood_ids, :facet => true
    # event categories
    has event_categories(:id), :as => :event_category_ids, :facet => true
    # event tags
    indexes event_tags.name, :as => :tags
    has event_tags(:id), :as => :tag_ids, :facet => true
  end
  
  def popular!
    # popularity value decreases the further away it is
    max_pop_value = 100
    days_from_now = (self.start_at > Time.now.beginning_of_day.utc) ? (self.start_at - Time.now) / 86400 : max_pop_value
    self.update_attribute(:popularity, max_pop_value - days_from_now)
  end

  def unpopular!
    self.update_attribute(:popularity, 0)
  end

  # return the event venue's name
  def venue_name
    # use the association location and place
    if self.location
      self.location.place_name
    else
      ""
    end
  end
  
  # returns true iff the location has a latitude and longitude 
  def mappable?
    return true if self.lat and self.lng
    false
  end

  def apply_category_tags!(category)
    return false if category.blank? or category.tags.blank?
    self.event_tag_list.add(category.tags.split(",")) 
    self.save
  end

  def remove_category_tags!(category)
    return false if category.blank? or category.tags.blank?
    category.tags.split(",").each { |s| self.event_tag_list.remove(s) }
    self.save
  end
  
  # remove event references
  def before_destroy_callback
    location.events.delete(self) if location
  end

  protected

  def after_add_category(category)
    return if category.tags.blank?
    # add category tags and save object
    apply_category_tags!(category)
    # increment counter cache
    EventCategory.increment_counter(:events_count, category.id)
  end
  
  def after_remove_category(category)
    return if category.tags.blank?
    # remove category tags and save object
    remove_category_tags!(category)
    # decrement counter cache
    EventCategory.decrement_counter(:events_count, category.id)
  end
  
end