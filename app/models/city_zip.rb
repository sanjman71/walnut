class CityZip < ActiveRecord::Base
  belongs_to                :city
  belongs_to                :zip
  validates_uniqueness_of   :city_id, :scope => :zip_id
end