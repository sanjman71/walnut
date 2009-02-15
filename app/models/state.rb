class State < ActiveRecord::Base
  validates_presence_of       :name, :code, :country_id
  validates_uniqueness_of     :name
  belongs_to                  :country
  has_many                    :cities
  has_many                    :zips
  has_many                    :locations

  include NameParam
end
