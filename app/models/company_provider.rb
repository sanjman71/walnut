class CompanyProvider < ActiveRecord::Base
  belongs_to                :company, :counter_cache => :providers_count
  belongs_to                :provider, :polymorphic => true
  validates_presence_of     :company_id, :provider_id, :provider_type
  validates_uniqueness_of   :company_id, :scope => [:provider_type, :provider_id]  # provider is unique for a company
  
  named_scope               :order_by_name, { :order => 'users.name, resources.name' }
end
