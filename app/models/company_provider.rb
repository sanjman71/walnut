class CompanyProvider < ActiveRecord::Base
  belongs_to                :company, :counter_cache => :providers_count
  belongs_to                :provider, :polymorphic => true
  validates_presence_of     :company_id, :provider_id, :provider_type
  validates_uniqueness_of   :company_id, :scope => [:provider_type, :provider_id]  # provider is unique for each company
  
  named_scope               :order_by_name, { :order => 'users.name, resources.name' }
  
  protected
  
  # add 'company provider' role to provider
  def after_create
    provider.grant_role('company provider', company) if provider.respond_to?(:grant_role)
  end
  
  # remove 'company provider' role from provider
  def before_destroy
    provider.revoke_role('company provider', company) if provider.respond_to?(:revoke_role)
  end
end
