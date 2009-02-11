class Chain < ActiveRecord::Base
  validates_presence_of     :name
  validates_uniqueness_of   :name
  has_many                  :places
  has_many                  :locations, :through => :places
  
  include NameModule
  
  # returns the total number of chain locations
  def count
    locations.size
  end

  # returns the list of states for the chain store
  def states
    locations.collect { |a| a.state }.uniq
  end

  # returns the list of states for the chain store
  def cities
    locations.collect { |a| a.city }.uniq
  end
  
end