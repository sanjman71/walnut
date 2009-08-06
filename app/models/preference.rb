# Preference
#
# This model allows any other model to have a list of associated preferences
# It ensures that the preference name is unique among all preferences of that polymorphic owner
#
class Preference < ActiveRecord::Base
  belongs_to                :preferable, :polymorphic => true
  validates_uniqueness_of   :name, :scope => [:preferable_id, :preferable_type]

  named_scope :pref,   lambda { |n| { :conditions => ["name = ?", n] }}
  named_scope :value,  lambda { |n| { :select => :value, :conditions => ["name = ?", n]}}
  named_scope :ivalue, lambda { |n| { :select => :ivalue, :conditions => ["name = ?", n]}}
  
end
