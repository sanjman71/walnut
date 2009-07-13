class LocationSource < ActiveRecord::Base
  belongs_to              :location
  belongs_to              :source, :polymorphic => true
  validates_presence_of   :location_id
  validates_presence_of   :source_id
  validates_presence_of   :source_type
  validates_uniqueness_of :location_id, :scope => [:source_id, :source_type]

  # find location with the specified source
  named_scope :find_by_source,        lambda { |source| { :conditions => {:source_id => source.id, :source_type => source.class.to_s} }}
  named_scope :find_by_source_id,     lambda { |source_id| { :conditions => {:source_id => source_id} }}
  named_scope :find_by_source_type,   lambda { |source_type| { :conditions => {:source_type => source_type} }}
end