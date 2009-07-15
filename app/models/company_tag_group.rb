class CompanyTagGroup < ActiveRecord::Base
  belongs_to                :company, :counter_cache => :tag_groups_count
  belongs_to                :tag_group, :counter_cache => :companies_count
  validates_uniqueness_of   :tag_group_id, :scope => :company_id
end