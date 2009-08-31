class ServiceProvider < ActiveRecord::Base
  belongs_to                :service, :counter_cache => :providers_count
  belongs_to                :provider, :polymorphic => true
  validates_presence_of     :service_id, :provider_id, :provider_type
  validates_uniqueness_of   :service_id, :scope => [:provider_type, :provider_id]  # provider is unique for each service
  
end
