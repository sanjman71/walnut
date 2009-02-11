class Chain < ActiveRecord::Base
  validates_presence_of     :name
  validates_uniqueness_of   :name
  has_many                  :places
  has_many                  :addresses, :through => :places
  
  include NameModule
  
  # returns the total number of chain addresses
  def count
    addresses.size
  end

  # returns the list of states for the chain store
  def states
    addresses.collect { |a| a.state }.uniq
  end
  
end