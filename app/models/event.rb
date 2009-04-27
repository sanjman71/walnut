class Event < ActiveRecord::Base
  validates_presence_of     :name, :event_venue_id, :source_type, :source_id
  validates_uniqueness_of   :source_id, :scope => :source_type

  belongs_to                :event_venue, :counter_cache => :events_count
  has_one                   :location, :through => :event_venue

  delegate                  :country, :to => '(location or return nil)'
  delegate                  :state, :to => '(location or return nil)'
  delegate                  :city, :to => '(location or return nil)'
  delegate                  :zip, :to => '(location or return nil)'
  delegate                  :neighborhoods, :to => '(location or return nil)'

  define_index do
    indexes name, :as => :name
    # locality attributes, all faceted
    has location.country(:id), :type => :integer, :as => :country_id, :facet => true
    has location.state(:id), :type => :integer, :as => :state_id, :facet => true
    has locaton.city(:id), :type => :integer, :as => :city_id, :facet => true
    has location.zip(:id), :type => :integer, :as => :zip_id, :facet => true
    has location.neighborhoods(:id), :as => :neighborhood_ids, :facet => true
  end
end