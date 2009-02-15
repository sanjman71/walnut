class Zip < ActiveRecord::Base
  validates_presence_of       :name, :state_id
  validates_format_of         :name, :with => /\d{5,5}/
  validates_uniqueness_of     :name, :scope => :state_id
  belongs_to                  :state, :counter_cache => true
  has_many                    :city_zips
  has_many                    :cities, :through => :city_zips
  has_many                    :locations
  
  include NameParam
end
