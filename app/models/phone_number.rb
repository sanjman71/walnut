class PhoneNumber < ActiveRecord::Base
  # validates_presence_of     :callable, :polymorphic => true # validation is done in a before filter so nested attributes work
  validates_presence_of     :name, :address
  validates_format_of       :address, :with => /[0-9]{10,11}/, :message => "Phone number is invalid. It should have 10 digits - area code and number."
  # Note: we allow duplicate phone numbers since it models real world usage more accurately than uniqueness
  # validates_uniqueness_of   :address, :case_sensitive => false, :message => "Phone number is already in use"
  validates_inclusion_of    :name, :in => ['Mobile', 'Work', 'Home', 'Other']
  before_validation         :format_phone
  belongs_to                :callable, :polymorphic => true, :counter_cache => :phone_numbers_count

  # BEGIN acts_as_state_machine
  include AASM
  aasm_column           :state
  aasm_initial_state    :unverified
  aasm_state            :unverified
  aasm_state            :verified

  aasm_event :verify do
    transitions :to => :verified, :from => [:unverified]
  end
  # END acts_as_state_machine
  
  named_scope               :with_callable_type, lambda { |t| { :conditions => {:callable_type => t} } }

  PRIORITY_HIGHEST    = 1
  PRIORITY_MEDIUM     = 2

  def before_validation_on_create
    # set default priority
    self.priority = 1 if self.priority.blank?
  end

  def before_create
    # validate callable
    if self.callable_id.blank? or self.callable_type.blank?
      self.errors.add_to_base("Phone number must have an owner")
      return false
    end
    true
  end

  def verified?
    self.state == 'verified'
  end

  # return true if the phone number is deletable
  def deletable?
    return false if new_record?
    true # all phones are deletable
  end

  # valid phone number names
  def self.names
    ['Mobile', 'Work', 'Home', 'Other']
  end
  
  # returns true if the string is a valid phone numers
  def self.phone?(s)
    format(s).match(/[0-9]{10,11}/)
  end

  def self.format(s)
    return s if s.blank?
    s.gsub(/[^\d]|^1/, '')
  end

  protected
  
  # format phone by removing all non-digits
  def format_phone
    self.address = PhoneNumber.format(self.address)
  end

end