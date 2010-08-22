require 'digest/sha1'
require 'serialized_hash'

class User < ActiveRecord::Base
  include Authentication
  include Authentication::ByPassword
  include Authentication::ByCookieToken
  include Authorization::AasmRoles

  # add states and events
  aasm_state :data_missing

  aasm_event :profile_data_missing  do
    transitions :from => [:active, :data_missing], :to => :data_missing
  end

  aasm_event :profile_complete do
    transitions :from => [:data_missing], :to => :active, :guard => :profile_complete?
  end

  # Badges for authorization
  badges_authorized_user

  validates_format_of       :name, :with => Authentication.name_regex,  :message => Authentication.bad_name_message, :allow_nil => true
  validates_length_of       :name, :maximum => 100
  validates_presence_of     :name

  # overrides Authentication::ByPassword validations
  validates_presence_of     :password,  :if => :password_required?
  validates_confirmation_of :password,  :if => :password_set?

  has_many                  :email_addresses, :as => :emailable, :dependent => :destroy, :order => "priority asc",
                            :after_add => :after_add_email_address, :after_remove => :after_remove_email_address
  has_one                   :primary_email_address, :class_name => 'EmailAddress', :as => :emailable, :order => "priority asc"
  accepts_nested_attributes_for :email_addresses, :allow_destroy => true, :reject_if => proc { |attrs| attrs.all? { |k, v| v.blank? } }
  has_many                  :phone_numbers, :as => :callable, :dependent => :destroy, :order => "priority asc",
                            :after_add => :after_add_phone_number, :after_remove => :after_remove_phone_number
  has_one                   :primary_phone_number, :class_name => 'PhoneNumber', :as => :callable, :order => "priority asc"
  accepts_nested_attributes_for :phone_numbers, :allow_destroy => true, :reject_if => proc { |attrs| attrs.all? { |k, v| v.blank? } }

  has_many                  :subscriptions, :dependent => :destroy
  has_many                  :ownerships, :through => :subscriptions, :source => :company

  has_many                  :company_providers, :as => :provider, :dependent => :destroy
  has_many                  :provided_companies, :through => :company_providers, :source => :company

  has_many                  :waitlists, :foreign_key => :customer_id

  validates_presence_of       :cal_dav_token
  validates_length_of         :cal_dav_token,   :within => 10..150
  validates_uniqueness_of     :cal_dav_token
  before_validation_on_create :reset_cal_dav_token

  has_many                    :message_topics, :as => :topic
  has_many                    :messages, :through => :message_topics

  # Appointments and capacity
  # TODO - what should be done with these when the user goes away?
  has_many                  :provided_appointments, :class_name => 'Appointment', :as => :provider
  has_many                  :created_appointments, :class_name => 'Appointment', :source => :creator
  has_many                  :customer_appointments, :class_name => 'Appointment', :foreign_key => 'customer_id'
  has_many                  :capacity_slots, :as => :provider

  # Preferences
  serialized_hash           :preferences, {:provider_email_text => '', :provider_email_daily_schedule => '0', :phone => 'optional', :email => 'optional'}

  # messages sent
  has_many                  :outbox, :class_name => "Message", :foreign_key => "sender_id"
  # messages received with 'local' protocol
  has_many                  :inbox_deliveries, :class_name => "MessageRecipient", :as => :messagable, :conditions => {:protocol => 'local'}, 
                            :include => {:message => :sender}
  has_many                  :inbox, :through => :inbox_deliveries, :source => :message

  after_create              :manage_user_roles, :activate_user
  after_update              :after_update_callback

  # HACK HACK HACK -- how to do attr_accessible from here?
  # prevents a user from submitting a crafted form that bypasses activation
  # anything else you want your user to change should be added here.
  attr_accessible           :name, :password, :password_confirmation, :rpx, :email_addresses_attributes, :phone_numbers_attributes, 
                            :capacity, :preferences_provider_email_text, :preferences_provider_email_daily_schedule,
                            :preferences_phone, :preferences_email

  named_scope               :with_emails, { :conditions => ["email_addresses_count > 0"] }
  named_scope               :no_emails, { :conditions => {'email_addresses_count' => 0} }
  named_scope               :with_email, lambda { |s| { :include => :email_addresses, :conditions => ["email_addresses.address = ?", s] } }
  named_scope               :with_identifier, lambda { |s| { :include => :email_addresses, :conditions => ["email_addresses.identifier = ?", s] } }
  named_scope               :with_phones, { :conditions => ["phone_numbers_count > 0"] }
  named_scope               :no_phones, { :conditions => {'phone_numbers_count' => 0} }
  named_scope               :with_phone, lambda { |s| { :include => :phone_numbers, :conditions => ["phone_numbers.address = ?", s] } }

  named_scope               :search_by_name, lambda { |s| { :conditions => ["LOWER(users.name) REGEXP '%s'", s.downcase] }}
  named_scope               :order_by_name, { :order => 'users.name' }

  named_scope               :search_by_name_email_phone, lambda { |s| {
                                                                  :include => [:email_addresses, :phone_numbers],
                                                                  :conditions => ["LOWER(users.name) LIKE ? OR LOWER(email_addresses.address) LIKE ? OR phone_numbers.address LIKE ?", '%' + s.downcase + '%', '%' + s.downcase + '%', '%' + s.downcase + '%']
                                                                  }}

  # include other required user modules
  include UserSubscription
  include UserAppointment
  include UserInvitation

  # Authenticates a user by their login name and unencrypted password.  Returns the user or nil.
  #
  # uff.  this is really an authorization, not authentication routine.  
  # We really need a Dispatch Chain here or something.
  # This will also let us return a human error message.
  #
  def self.authenticate(email_or_phone, password, options={})
    return nil if email_or_phone.blank?
    if PhoneNumber.phone?(email_or_phone)
      # phone authentication
      users = self.with_phone(PhoneNumber.format(email_or_phone)).find_in_states(:all, [:active, :data_missing])# need to get the salt
    else
      # assume email authentication
      users = self.with_email(email_or_phone).find_in_states(:all, [:active, :data_missing]) # need to get the salt
    end
    # authentication fails if there is no user or more than 1 user
    return nil if users.empty? or users.size > 1
    u = users.first
    # check is user password is blank
    return u if u.crypted_password.blank? and u.password.blank? and password.blank?
    # authenticate
    u.authenticated?(password) ? u : nil
  end

  # find users in the specified states
  def self.find_in_states(number, states)
    self.find(number, :conditions => ["users.state IN (?)", states.map(&:to_s)])
  end

  def self.create_rpx(name, email, identifier, options={})
    User.transaction do
      # create user in passive state
      user  = self.create({:name => name, :rpx => 1}.update(options))
      # rpx users don't always have emails
      unless email.blank?
        # add email address with rpx identifier
        email = user.email_addresses.create(:address => email, :identifier => identifier)
        # change email state to verfied
        email.verify!
      end
      user
    end
  end
  
  def self.generate_password(length=6)
    chars    = 'abcdefghjkmnpqrstuvwxyzABCDEFGHJKLMNOPQRSTUVWXYZ23456789'
    password = ''
    length.times { |i| password << chars[rand(chars.length)] }
    password
  end

  # the special user 'anyone'
  def self.anyone(name = 'Anyone')
    r = User.new do |o|
      o.name = name
      o.send(:id=, 0)
    end
  end

  # return true if its the special user 'anyone'
  def anyone?
    self.id == 0
  end

  # return true if the user is a provider
  def provider?
    self.company_providers.count > 0
  end

  def rpx?
    self.rpx == 1
  end

  def profile_complete?
    return false if (self.reload.email_missing? or self.reload.phone_missing?)
    true
  end

  # return true if a email address is required but user doesn't have one
  def email_missing?
    case self.preferences[:email]
    when 'optional'
      false
    when 'required'
      self.email_addresses_count == 0
    else
      false
    end
  end

  # address of primary email address
  def email_address
    @email_address ||= self.email_addresses_count > 0 ? self.primary_email_address.address : ''
  end

  # return true if a phone number is required but user doesn't have one
  def phone_missing?
    case self.preferences[:phone]
    when 'optional'
      false
    when 'required'
      self.phone_numbers_count == 0
    else
      false
    end
  end

  # address of primary phone number
  def phone_number
    @phone_number ||= self.phone_numbers_count > 0 ? self.primary_phone_number.address : ''
  end

  def password?
    !self.crypted_password.blank?
  end

  def tableize
    self.class.to_s.tableize
  end
  
  def reset_cal_dav_token
    cal_dav_token_will_change!
    # We generate a token with no forward slashes in it, by substituting for / with |.
    self.cal_dav_token = ActiveSupport::SecureRandom.base64(50).gsub('/', '|')
  end
  
  protected
    
  # password is not required
  def password_required?
    return false
  end

  def password_set?
    !self.password.blank?
  end

  def make_activation_code
    self.deleted_at = nil
    self.activation_code = self.class.make_token
  end

  def manage_user_roles
    unless self.has_role?('user manager', self)
      # all users can manage themselves
      self.grant_role('user manager', self)
    end
  end

  def activate_user
    if self.password.blank? and self.crypted_password.blank? and self.state == 'passive'
      # force state to active
      self.update_attribute(:state, 'active')
    elsif self.state == 'passive'
      # register and activate all users
      self.register!
      self.activate!
    end

    # check if user is missing any data
    if self.reload.email_missing? or self.reload.phone_missing?
      self.profile_data_missing!
    end
  end

  def after_add_email_address(email_address)
    return if email_address.new_record?
    self.profile_complete! if self.data_missing?
  end

  def after_remove_email_address(email_address)
    return if email_address.new_record?
    if self.active? and self.reload.email_missing?
      self.profile_data_missing!
    end
  end

  def after_add_phone_number(phone_number)
    return if phone_number.new_record?
    self.profile_complete! if self.data_missing?
  end

  def after_remove_phone_number(phone_number)
    return if phone_number.new_record?
    if self.active? and self.reload.phone_missing?
      self.profile_data_missing!
    end
  end
  
  def after_update_callback
    # when a user's phone or email is added using update_attributes, the after_add callbacks are not called
    # check if user is in the data_missing state and the missing data has been added
    if self.data_missing? and self.profile_complete?
      self.profile_complete!
    end
  end

end
