class Payment < ActiveRecord::Base
  serialize               :params 
  cattr_accessor          :gateway 
  validates_presence_of   :description
  belongs_to              :subscription
  
  # BEGIN acts_as_state_machhine
  include AASM
  
  aasm_column           :state
  aasm_initial_state    :pending
  aasm_state            :pending
  aasm_state            :authorized
  aasm_state            :paid
  aasm_state            :declined
  
  aasm_event :authorized do
    transitions :to => :authorized, :from => [:pending, :declined]
  end
  
  aasm_event :captured do
    transitions :to => :paid, :from => [:authorized]
  end

  aasm_event :paid do
    transitions :to => :paid, :from => [:pending]
  end
  
  aasm_event :declined do
    transitions :to => :declined, :from => [:pending]
    transitions :to => :declined, :from => [:declined]
    transitions :to => :authorized, :from => [:authorized] 
  end
  # END acts_as_state_machine
  
  def authorize(amount, credit_card, options = {})
    # generate a unique order id
    options[:order_id] = number
    
    transaction do
      process('authorization', amount) do |gw| 
        gw.authorize(amount, credit_card, options) 
      end
      
      # change state based on whether the transaction was successful
      if self.success? 
        authorized!
      else 
        declined!
      end
    end
  end
  
  def purchase(amount, credit_card, options = {})
    transaction do
      process('purchase', amount) do |gw| 
        gw.purchase(amount, credit_card, options) 
      end
      
      # change state based on whether the transaction was successful
      if self.success? 
        paid!
      else 
        declined!
      end
    end
  end
    
  protected
  
  # used to generate a unique order id
  def number
    ActiveSupport::SecureRandom.hex(16)
    # ActionController::Session.generate_unique_id 
  end
  
  def process(action, amount = nil) 
    self.amount = amount 
    self.action = action 

    begin 
      response = yield Payment.gateway 

      self.success   = response.success? 
      self.reference = response.authorization
      self.message   = response.message 
      self.params    = response.params 
      self.test      = response.test?
    rescue ActiveMerchant::ActiveMerchantError => e 
      self.success   = false 
      self.reference = nil 
      self.message   = e.message 
      self.params    = {} 
      self.test      = gateway.test? 
    end
  end
  
end