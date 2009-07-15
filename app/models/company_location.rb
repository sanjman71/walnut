class CompanyLocation < ActiveRecord::Base
  validates_presence_of     :location_id, :company_id
  validates_uniqueness_of   :company_id, :scope => :location_id
  belongs_to                :company, :counter_cache => :locations_count
  belongs_to                :location
end