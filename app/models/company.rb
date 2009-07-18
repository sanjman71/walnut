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

  has_many                  :company_locations
  has_many                  :locations, :through => :company_locations, :after_add => :after_add_location, :after_remove => :after_remove_location

  has_many                  :phone_numbers, :as => :callable

  has_many                  :company_tag_groups
  has_many                  :tag_groups, :through => :company_tag_groups

  has_many                  :states, :through => :locations
  has_many                  :cities, :through => :locations
  has_many                  :zips, :through => :locations

  belongs_to                :timezone
  belongs_to                :chain, :counter_cache => true

  # Appointment-related info
  has_many                  :company_providers
  has_many_polymorphs       :providers, :from => [:users, :resources], :through => :company_providers
  has_many                  :company_services
  has_many                  :services, :through => :company_services, :after_add => :after_add_service, :after_remove => :after_remove_service
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

  acts_as_taggable_on       :tags
  
  named_scope :with_locations,      { :conditions => ["locations_count > 0"] }
  named_scope :with_chain,          { :conditions => ["chain_id is NOT NULL"] }
  named_scope :no_chain,            { :conditions => ["chain_id is NULL"] }
  named_scope :with_tag_groups,     { :conditions => ["tag_groups_count > 0"] }
  named_scope :no_tag_groups,       { :conditions => ["tag_groups_count = 0"] }
  named_scope :with_taggings,       { :conditions => ["taggings_count > 0"] }
  named_scope :no_taggings,         { :conditions => ["taggings_count = 0"] }

  # find all subscriptions with billing errors
  named_scope :billing_errors,      { :include => :subscription, :conditions => ["subscriptions.billing_errors_count > 0"] }

  def self.customer_role
    Badges::Role.find_by_name('customer')
  end

  def primary_location
    return nil if locations_count == 0
    locations.first
  end
  
  def primary_phone_number
    return nil if phone_numbers_count == 0
    phone_numbers.first
  end

  def chain?
    !self.chain_id.blank?
  end
  
  # return true if the company contains the specified provider
  def has_provider?(object)
    # can't use providers.include?(object) here, not sure why but possibly because its polymorphic
    providers.any? { |o| o == object }
  end
  
  # return the company free service
  def free_service
    @free_service ||= (services.free.first || services.create(:name => Service::AVAILABLE, :mark_as => "free", :price => 0.00))
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
  
  def after_remove_tagging(tagging)
    Company.decrement_counter(:taggings_count, id)
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
      # increment company work services count
      Company.decrement_counter(:work_services_count, self.id)
    end
  end
end