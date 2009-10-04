class Waitlist < ActiveRecord::Base
  belongs_to                  :company
  belongs_to                  :service
  belongs_to                  :provider, :polymorphic => true
  belongs_to                  :customer, :class_name => 'User'
  belongs_to                  :creator, :class_name => 'User'
  belongs_to                  :location

  validates_presence_of       :company_id
  validates_presence_of       :service_id
  validates_presence_of       :customer_id
  # validates_presence_of       :provider_id, :if => :provider_required?
  # validates_presence_of       :provider_type, :if => :provider_required?

  after_create                :grant_company_customer_role

  has_many                      :waitlist_time_ranges, :dependent => :destroy
  accepts_nested_attributes_for :waitlist_time_ranges, :allow_destroy => true

  protected
  
  # add 'company customer' role to the waitlist customer
  def grant_company_customer_role
    self.customer.grant_role('company customer', self.company) unless self.customer.has_role?('company customer', self.company)
  end
  
end