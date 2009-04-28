class Event < ActiveRecord::Base
  validates_presence_of     :name, :event_venue_id, :source_type, :source_id
  validates_uniqueness_of   :source_id, :scope => :source_type

  belongs_to                :event_venue, :counter_cache => :events_count
  has_one                   :location, :through => :event_venue

  has_many                  :event_category_mappings
  has_many                  :event_categories, :through => :event_category_mappings, :after_add => :after_add_category, :after_remove => :after_remove_category
  
  acts_as_taggable_on       :event_tags

  delegate                  :country, :to => '(location or return nil)'
  delegate                  :state, :to => '(location or return nil)'
  delegate                  :city, :to => '(location or return nil)'
  delegate                  :zip, :to => '(location or return nil)'
  delegate                  :neighborhoods, :to => '(location or return nil)'

  define_index do
    indexes name, :as => :name
    # locality attributes, all faceted
    has location.country_id, :type => :integer, :as => :country_id, :facet => true
    has location.state_id, :type => :integer, :as => :state_id, :facet => true
    has location.city_id, :type => :integer, :as => :city_id, :facet => true
    has location.zip_id, :type => :integer, :as => :zip_id, :facet => true
    has location.neighborhoods(:id), :as => :neighborhood_ids, :facet => true
    # event categories
    has event_categories(:id), :as => :event_category_ids, :facet => true
    # event tags
    indexes event_tags.name, :as => :event_tags
    has event_tags(:id), :as => :event_tag_ids, :facet => true
  end
  
  @@get_method      = "events/get"
  
  # get event info, e.g. tags, categories, ...
  def get(options={})
    get_options = {:id => self.source_id}
    EventVenue.session.call(@@get_method, get_options.update(options))
  end
  
  protected
  
  def after_add_category(category)
    return if category.tag_list.blank?
    # add tags and save object
    self.event_tag_list.add(category.tag_list.split(",")) 
    self.save
  end
  
  def after_remove_category(category)
    return if category.tag_list.blank?
    # remove tags and save object
    category.tag_list.split(",").each { |s| self.event_tag_list.remove(s) }
    self.save
  end
end