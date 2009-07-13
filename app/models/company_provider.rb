class CompanyProvider < ActiveRecord::Base
  belongs_to                :company, :counter_cache => :providers_count
  belongs_to                :provider, :polymorphic => true
  validates_presence_of     :company_id, :provider_id, :provider_type
  
  named_scope               :order_by_name, { :order => 'users.name, resources.name' }
  
  protected
  
  # add 'provider' role to provider
  def after_create
    provider.grant_role('provider', company) if provider.respond_to?(:grant_role)
  end
  
  # remove 'provider' role from provider
  def before_destroy
    provider.revoke_role('provider', company) if provider.respond_to?(:revoke_role)
  end
end
