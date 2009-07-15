class SubscriptionError < StandardError; end

class Subscription < ActiveRecord::Base
  validates_presence_of   :plan_id, :user_id, :company_id, :paid_count, :billing_errors_count
  validates_uniqueness_of :company_id
  belongs_to              :user
  belongs_to              :company
  belongs_to              :plan
  has_many                :payments
  
  after_create            :after_subcription_create
  
  attr_accessible         :plan_id, :user_id, :company_id, :plan, :user, :company

  delegate                :cost, :to => :plan
  
  # find all subscriptions with billing errors
  named_scope             :billing_errors, { :conditions => ["billing_errors_count > 0"] }
  
  # BEGIN acts_as_state_machhine
  include AASM
  
  aasm_column           :state
  aasm_initial_state    :initialized
  aasm_state            :initialized
  aasm_state            :authorized
  aasm_state            :active       # subscription billed successfully
  aasm_state            :frozen       # payment declined while in active state
  
  aasm_event :authorized do
    transitions :to => :authorized, :from => [:initialized, :active, :authorized]
  end

  aasm_event :active do
    transitions :to => :active, :from => [:authorized, :active]
  end

  aasm_event :frozen do
    transitions :to => :frozen, :from => [:authorized, :active, :frozen]
  end
  # END acts_as_state_machine

  def after_initialize
    # after_initialize can also be called when retrieving objects from the database
    return unless new_record?
    
    # use plan start billing date, store as utc value
    self.start_billing_at     = self.plan.start_billing_at.utc unless plan.blank? or !plan.billable?
    self.paid_count           = 0
    self.billing_errors_count = 0
  end
    
  # authorize the payment and create a vault id
  def authorize(credit_card, options = {})
    # create payment
    @payment = Payment.create(:description => "authorize subscription")
    payments.push(@payment)
    
    transaction do
      # authorize payment, and request a vault id
      @payment.authorize(cost, credit_card, :store => true)
    
      if @payment.authorized?
        # transition to authorized state
        authorized!

        # store the vault id
        self.vault_id = @payment.params['customer_vault_id']
        
        # set the next billing date if we don't have one
        # if we have a next_billing_at date, then this is a credit card update, and we shouldn't change
        # the next billing date
        if self.next_billing_at.blank?
          self.next_billing_at = self.start_billing_at
        end
        
        # commit changes
        self.save
      else
        # no transition, stay in initialized state
        
        # add errors
        errors.add_to_base("Credit card is invalid")
      end

      @payment
    end
  end
  
  # returns true if the associated plan is billable
  def billable?
    plan.billable?
  end
  
  # bill the credit card referenced by the vault id, or using the credit card specified
  def bill(credit_card = nil)
    if self.next_billing_at.to_date > Date.today
      raise SubscriptionError, "next billing date is in the future"
    end
    
    # create payment
    @payment = Payment.create(:description => "recurring billing")
    payments.push(@payment)
    
    transaction do
      # purchase using the customer vault id, or the credit card if its specified
      @payment.purchase(cost, credit_card || vault_id)
    
      if @payment.paid?
        # transition to active state
        active!

        # increment paid count
        self.paid_count = self.paid_count + 1
        
        # set the last bill date to now
        self.last_billing_at = Time.now

        # set next billing date as an integer number of billing cycles from the start billing date, store as utc value
        self.next_billing_at = self.start_billing_at.utc + plan.billing_cycle(self.paid_count)

        # reset billing errors count
        self.billing_errors_count = 0
        
        # commit changes
        self.save
      else
        # leave state alone but increment billing errors count
        self.billing_errors_count = self.billing_errors_count + 1

        # commit changes
        self.save
      end

      @payment
    end
  end

  protected

  def after_subcription_create
    # create company free service
    self.company.free_service
  end
end