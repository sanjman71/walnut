class EmailAddress < ActiveRecord::Base
  validates_presence_of     :address, :priority
  validates_presence_of     :emailable, :polymorphic => true
  validates_length_of       :address, :within => 6..100 #r@a.wk
  validates_uniqueness_of   :address, :case_sensitive => false
  validates_format_of       :address, :with => Authentication.email_regex, :message => Authentication.bad_email_message
  validates_uniqueness_of   :address, :scope => [:emailable_id, :emailable_type]
  belongs_to                :emailable, :polymorphic => true, :counter_cache => :email_addresses_count

  after_create              :manage_user_roles

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

  named_scope               :with_emailable_type, lambda { |t| { :conditions => {:emailable_type => t} } }
  named_scope               :with_emailable_user, {:conditions => {:emailable_type => 'User'}}
  named_scope               :with_address, lambda { |t| { :conditions => {:address => t} } }

  PRIORITY_HIGHEST    = 1
  PRIORITY_MEDIUM     = 2

  def before_validation_on_create
    # set default priority
    self.priority = 1 if self.priority.blank?
  end

  def verified?
    self.state == 'verified'
  end
  
  def protocol
    'email'
  end
  
  # returns true if this email address is changeable
  def changeable?
    # email addresses tied to rpx accounts are not changeable
    if !self.address.blank? and !self.identifier.blank?
      false
    else
      true
    end
  end

  protected
  
  def manage_user_roles
    if defined?(ADMIN_USER_EMAILS) and ADMIN_USER_EMAILS.include?(self.address) and self.emailable.is_a?(User)
      # grant user emailable the 'admin' role
      self.emailable.grant_role('admin')
    end
  end

end