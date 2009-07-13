class Company < ActiveRecord::Base
  extend ActiveSupport::Memoizable
  
  # Badges for authorization
  badges_authorizable_object

  validates_uniqueness_of   :name
  validates_presence_of     :name

  # Subdomain rules
  validates_presence_of     :subdomain
  validates_format_of       :subdomain,
                            :with => /^[A-Za-z0-9-]+$/,
                            :message => 'The subdomain can only contain alphanumeric characters and dashes.',
                            :allow_blank => true
  validates_uniqueness_of   :subdomain,
                            :case_sensitive => false
  validates_exclusion_of    :subdomain,
                            :in => %w( support blog www billing help api ),
                            :message => "The subdomain <strong>{{value}}</strong> is reserved and unavailable."

  before_validation         :init_subdomain, :downcase_subdomain, :titleize_name

  validates_presence_of     :time_zone
  has_many                  :company_providers
  has_many_polymorphs       :providers, :from => [:users, :resources], :through => :company_providers
  has_many                  :company_services
  has_many                  :services, :through => :company_services, :after_add => :added_service, :after_remove => :removed_service
  has_many                  :products
  has_many                  :appointments
  has_many                  :customers, :through => :appointments, :uniq => true
  has_many                  :invitations
  
  # Accounting info
  has_one                   :subscription
  has_one                   :owner, :through => :subscription, :source => :user
  has_one                   :plan, :through => :subscription

  # LogEntry log
  has_many                  :log_entries
  
  # Locations
  has_many                  :locatables_locations, :as => :locatable
  has_many                  :locations, :through => :locatables_locations

  # after create filter to initialize basic services that are provided by all companies
  after_create              :init_basic_services

  # find all subscriptions with billing errors
  named_scope               :billing_errors, { :include => :subscription, :conditions => ["subscriptions.billing_errors_count > 0"] }

  def self.customer_role
    Badges::Role.find_by_name('customer')
  end

  def self.provider_role
    Badges::Role.find_by_name("provider")
  end

  def self.manager_role
    Badges::Role.find_by_name("manager")
  end

  def validate
    if self.subscription.blank?
      errors.add_to_base("Subscription is not valid")
    end
  end

  # return true if the company contains the specified provider
  def has_provider?(object)
    # can't use providers.include?(object) here, not sure why but possibly because its polymorphic
    providers.any? { |o| o == object }
  end
  
  # return the company free service
  def free_service
    services.free.first
  end
  
  # returns true if the company has at least 1 provider and 1 work service
  def setup?
    return false if providers_count == 0 or work_services_count == 0
    true
  end
  
  def locations_with_any
    Array(Location.anywhere) + self.locations
  end

  # Plan tests
  def may_add_location?
    self.plan.may_add_location?(self)
  end
  
  def may_add_provider?
    self.plan.may_add_provider?(self)
  end  
  
  protected

  def downcase_subdomain
    self.subdomain.downcase! if attribute_present?("subdomain")
  end
  
  # initialize subdomain based on company name
  def init_subdomain
    if !attribute_present?("subdomain")
      self.subdomain = self.name.downcase.gsub(/[^\w\d]/, '') unless self.name.blank?
    end
  end
  
  def titleize_name
    self.name = self.name.titleize unless self.name.blank?
  end
  
  # initialize company's basic services
  def init_basic_services
    # add company free service
    services.push(Service.find_or_create_by_name(:name => Service::AVAILABLE, :mark_as => "free", :price => 0.00))
  end
  
  # manage both the services count and work service count
  def added_service(service)
    Company.increment_counter(:services_count, self.id)
    if service.mark_as == Appointment::WORK
      # increment company work services count
      Company.increment_counter(:work_services_count, self.id)
    end
  end

  # manage both the services count and work service count
  def removed_service(service)
    Company.decrement_counter(:services_count, self.id)
    if service.mark_as == Appointment::WORK
      # increment company work services count
      Company.decrement_counter(:work_services_count, self.id)
    end
  end
end
