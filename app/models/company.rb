require 'serialized_hash'

class Company < ActiveRecord::Base
  extend ActiveSupport::Memoizable
  
  # Badges for authorization
  badges_authorizable_object
  
  validates_presence_of     :name
  
  # Subdomain rules
  validates_presence_of     :subdomain
  validates_format_of       :subdomain,
                            :with => /^[A-Za-z0-9-]+$/,
                            :message => 'The subdomain can only contain alphanumeric characters and dashes.',
                            :allow_blank => true
  # validates_uniqueness_of   :subdomain,
  #                           :case_sensitive => false
  validates_exclusion_of    :subdomain,
                            :in => %w( support blog www billing help api ),
                            :message => "The subdomain <strong>{{value}}</strong> is reserved and unavailable."

  before_validation         :init_subdomain, :downcase_subdomain, :titleize_name

  # validates_presence_of     :time_zone

  # We don't destroy the locations associated with a company if it's destroyed as they might be associated with another.
  has_many                  :company_locations, :dependent => :destroy
  has_many                  :locations, :through => :company_locations, :after_add => :after_add_location, :after_remove => :after_remove_location

  has_many                  :phone_numbers, :as => :callable, :dependent => :destroy
  has_one                   :primary_phone_number, :class_name => 'PhoneNumber', :as => :callable, :order => "priority asc"

  has_many                  :company_tag_groups, :dependent => :destroy
  has_many                  :tag_groups, :through => :company_tag_groups

  has_many                  :states, :through => :locations
  has_many                  :cities, :through => :locations
  has_many                  :zips, :through => :locations

  belongs_to                :timezone
  belongs_to                :chain, :counter_cache => true

  # Appointment-related info
  has_many                  :company_providers, :dependent => :destroy
  has_many                  :user_providers, :through => :company_providers, :source => :provider, :source_type => 'User',
                            :after_add => :after_add_provider, :after_remove => :after_remove_provider
  has_many                  :resource_providers, :through => :company_providers, :source => :provider, :source_type => 'Resource',
                            :after_add => :after_add_provider, :after_remove => :after_remove_provider
  has_many                  :services, :dependent => :destroy, :after_add => :after_add_service, :after_remove => :after_remove_service
  has_many                  :products, :dependent => :destroy
  has_many                  :appointments, :dependent => :destroy
  has_many                  :capacity_slots, :through => :appointments, :foreign_key => :free_appointment_id
  has_many                  :customers, :through => :appointments, :uniq => true
  has_many                  :invitations, :dependent => :destroy
  has_many                  :waitlists, :dependent => :destroy

  has_many                  :capacity_slot2s, :dependent => :destroy

  # Accounting info
  has_one                   :subscription, :dependent => :destroy
  has_one                   :owner, :through => :subscription, :source => :user
  has_one                   :plan, :through => :subscription

  # Delegate state to subscription
  delegate                  :state, :to => '(subscription or return nil)'

  # Message deliveries
  has_many                  :company_message_deliveries
  has_many                  :messages, :through => :company_message_deliveries

  # LogEntry log - deprecated
  # has_many                  :log_entries, :dependent => :destroy

  # Logo
  has_one                   :logo, :dependent => :destroy
  accepts_nested_attributes_for :logo, :allow_destroy => true

  # Roles through badges associations
  has_many                  :authorized_managers, :through => :user_roles, :source => :user,
                            :conditions => ['badges_user_roles.role_id = #{Company.manager_role.id}']

  has_many                  :authorized_providers, :through => :user_roles, :source => :user,
                            :conditions => ['badges_user_roles.role_id = #{Company.provider_role.id}']

  has_many                  :authorized_customers, :through => :user_roles, :source => :user,
                            :conditions => ['badges_user_roles.role_id = #{Company.customer_role.id}']

  # Preferences
  serialized_hash           :preferences,
                            {:time_horizon => 28.days, :start_wday => '0', :appt_start_minutes => [0], :public => '1',
                             :work_appointment_confirmation_customer => '0',
                             :work_appointment_confirmation_manager => '0',
                             :work_appointment_confirmation_provider => '0'}

  acts_as_taggable_on       :tags
  
  named_scope :with_locations,      { :conditions => ["locations_count > 0"] }
  named_scope :with_chain,          { :conditions => ["chain_id is NOT NULL"] }
  named_scope :no_chain,            { :conditions => ["chain_id is NULL"] }
  named_scope :with_tag_groups,     { :conditions => ["tag_groups_count > 0"] }
  named_scope :no_tag_groups,       { :conditions => ["tag_groups_count = 0"] }
  named_scope :with_taggings,       { :conditions => ["taggings_count > 0"] }
  named_scope :no_taggings,         { :conditions => ["taggings_count = 0"] }

  # find all companies with subscriptions
  named_scope :with_subscriptions,  { :joins => :subscription, :conditions => ["subscriptions.id > 0"] }

  # find all subscriptions with billing errors
  named_scope :billing_errors,      { :include => :subscription, :conditions => ["subscriptions.billing_errors_count > 0"] }


  def self.provider_role
    Badges::Role.find_by_name('company provider')
  end

  def self.customer_role
    Badges::Role.find_by_name('company customer')
  end

  def self.manager_role
    Badges::Role.find_by_name('company manager')
  end

  # find all polymorphic providers through the company_providers collection, sort by name
  def providers
    self.company_providers(:include => :provider).collect(&:provider).sort_by{ |p| p.name }
  end

  def primary_location
    return nil if locations_count == 0
    locations.first
  end

  def chain?
    !self.chain_id.blank?
  end
  
  # return true if the company contains the specified provider
  def has_provider?(object)
    self.providers.include?(object)
  end
  
  # return the company free service
  def free_service
    @free_service ||= (self.services.free.first || self.services.create(:name => Service::AVAILABLE, :mark_as => "free", :price => 0.00))
  end
  
  # check if the company plan allows more locations
  def may_add_location?
    self.plan.may_add_location?(self)
  end
  
  # check if the company plan allows more providers
  def may_add_provider?
    self.plan.may_add_provider?(self)
  end  

  private
  
  # initialize subdomain based on company name
  def init_subdomain
    if !attribute_present?("subdomain")
      self.subdomain = self.name.downcase.gsub(/[^\w\d]/, '') unless self.name.blank?
    end
  end

  def downcase_subdomain
    self.subdomain.downcase! if attribute_present?("subdomain")
  end

  def titleize_name
    self.name = self.name.titleize unless self.name.blank?
  end
  
  def after_add_location(location)
    return if location.blank?

    # Note: incrementing the counter cache is done using built-in activerecord callback
  end
  
  def after_remove_location(location)
    return if location.blank?

    # decrement locations_count counter cache
    # TODO: find out why the built-in counter cache doesn't work here
    Company.decrement_counter(:locations_count, id)
  end
  
  def after_remove_tagging(tag)
    Company.decrement_counter(:taggings_count, id)
    Tag.decrement_counter(:taggings_count, tag.id)
  end
  
  # manage both the services count and work service count
  def after_add_service(service)
    Company.increment_counter(:services_count, self.id)
    if service.mark_as == Appointment::WORK
      # increment company work services count
      Company.increment_counter(:work_services_count, self.id)
    end
  end

  # manage both the services count and work service count
  def after_remove_service(service)
    Company.decrement_counter(:services_count, self.id)
    if service.mark_as == Appointment::WORK
      # decrement company work services count
      Company.decrement_counter(:work_services_count, self.id)
    end
  end
  
  def after_add_provider(provider)
    if provider.respond_to?(:has_role?) and !provider.has_role?('company provider', self)
      # assign company roles to provider
      provider.grant_role('company provider', self)
    end
  end

  def after_remove_provider(provider)
    # the decrement counter cache doesn't work, so decrement here
    Company.decrement_counter(:providers_count, self.id) if provider
    
    # check provider to see if they provide any services to this company
    if provider.respond_to?(:has_role?) and provider.has_role?('company provider', self) and !provider.provided_companies.include?(self)
      # revoke company roles from provider
      provider.revoke_role('company provider', self)
    end
  end
  
end
