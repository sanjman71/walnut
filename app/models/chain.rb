class Chain < ActiveRecord::Base
  validates_presence_of     :name
  validates_uniqueness_of   :name
  has_many                  :places
  has_many                  :locations, :through => :places
  
  include NameParam
  
  named_scope :zero,        { :conditions => {:places_count => 0} }
  named_scope :places,      { :conditions => ["places_count > 0"] }
  
  # returns the total number of chain locations
  def count
    locations.size
  end

  # returns the list of states for the chain store
  def states
    locations.collect(&:state).uniq
  end
  
  # returns the list of states for the chain store
  def cities
    locations.collect(&:city).uniq
  end
  
end