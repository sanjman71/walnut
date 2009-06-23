class Chain < ActiveRecord::Base
  validates_presence_of     :name
  validates_uniqueness_of   :name
  has_many                  :places
  
  include NameParam
  
  # used to generated an seo friendly url parameter
  acts_as_friendly_param    :name
  
  named_scope :no_places,   { :conditions => {:places_count => 0} }
  named_scope :places,      { :conditions => ["places_count > 0"] }


  def display_name
    @display_name = read_attribute(:display_name)
    @display_name.blank? ? self.name : @display_name
  end
end