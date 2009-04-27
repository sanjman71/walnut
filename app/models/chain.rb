class Chain < ActiveRecord::Base
  validates_presence_of     :name
  validates_uniqueness_of   :name
  has_many                  :places
  
  include NameParam
  
  named_scope :no_places,   { :conditions => {:places_count => 0} }
  named_scope :places,      { :conditions => ["places_count > 0"] }
  
end