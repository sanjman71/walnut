require 'digest/sha1'
require 'serialized_hash'

class User < ActiveRecord::Base
  include Authentication
  include Authentication::ByPassword
  include Authentication::ByCookieToken
  include Authorization::AasmRoles

  include UserAuthIdentity

  # Badges for authorization
  badges_authorized_user

  validates_format_of       :name, :with => Authentication.name_regex,  :message => Authentication.bad_name_message, :allow_nil => true
  validates_length_of       :name, :maximum => 100
  validates_presence_of     :name

  has_many                  :email_addresses, :as => :emailable, :dependent => :destroy
  has_one                   :primary_email_address, :class_name => 'EmailAddress', :as => :emailable, :order => "priority asc"
  accepts_nested_attributes_for :email_addresses, :allow_destroy => true, :reject_if => proc { |attrs| attrs.all? { |k, v| v.blank? } }
  has_many                  :phone_numbers, :as => :callable, :dependent => :destroy
  has_one                   :primary_phone_number, :class_name => 'PhoneNumber', :as => :callable, :order => "priority asc"
  accepts_nested_attributes_for :phone_numbers, :allow_destroy => true, :reject_if => proc { |attrs| attrs.all? { |k, v| v.blank? } }

  has_many                  :subscriptions, :dependent => :destroy
  has_many                  :ownerships, :through => :subscriptions, :source => :company

  has_many                  :company_providers, :as => :provider, :dependent => :destroy
  has_many                  :companies, :through => :company_providers, :source => :company

  validates_presence_of       :cal_dav_token
  validates_length_of         :cal_dav_token,   :within => 10..150
  validates_uniqueness_of     :cal_dav_token
  before_validation_on_create :reset_cal_dav_token

  # Preferences
  serialized_hash           :preferences

  # messages sent
  has_many                  :outbox, :class_name => "Message", :foreign_key => "sender_id"
  # messages received with 'local' protocol
  has_many                  :inbox_deliveries, :class_name => "MessageRecipient", :as => :messagable, :conditions => {:protocol => 'local'}, 
                            :include => {:message => :sender}
  has_many                  :inbox, :through => :inbox_deliveries, :source => :message

  after_create              :manage_user_roles

  # HACK HACK HACK -- how to do attr_accessible from here?
  # prevents a user from submitting a crafted form that bypasses activation
  # anything else you want your user to change should be added here.
  attr_accessible           :name, :password, :password_confirmation, :rpx, :email_addresses_attributes, :phone_numbers_attributes

  named_scope               :with_emails, { :conditions => ["email_addresses_count > 0"] }
  named_scope               :with_email, lambda { |s| { :include => :email_addresses, :conditions => ["email_addresses.address = ?", s] } }
  named_scope               :with_identifier, lambda { |s| { :include => :email_addresses, :conditions => ["email_addresses.identifier = ?", s] } }
  named_scope               :with_phones, lambda { |s| { :conditions => ["phone_numbers_count > 0"] }}

  named_scope               :search_by_name, lambda { |s| { :conditions => ["LOWER(users.name) REGEXP '%s'", s.downcase] }}
  named_scope               :order_by_name, { :order => 'users.name' }

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
  def self.authenticate(email, password, options={})
    return nil if email.blank? || password.blank?
    u = self.with_email(email).find_in_state(:first, :active) # need to get the salt
    u && u.authenticated?(password) ? u : nil
  end

  # create new user or reset user's password
  def self.create_or_reset(options={})
    if !options[:email].blank?
      email = options.delete(:email)
      user  = self.with_email(email).first
    elsif !options[:email_addresses_attributes].blank?
      email_addresses_attributes = options.delete(:email_addresses_attributes)
    end

    case options[:password]
    when :random
      password = User.generate_password(10)
    else
      password = options[:password].to_s
    end

    if user
      # reset password
      user.password = password
      user.password_confirmation = password
      user.save
      # send user password reset
      Delayed::Job.enqueue(UserJob.new(:id => user.id, :password => password, :method => 'send_password_reset'))
    else
      User.transaction do
        # create user in active state
        name = options[:name]
        user = self.create(:name => name, :password => password, :password_confirmation => password)
        user.register!
        user.activate!
        
        case
        when email
          # add email address
          email = user.email_addresses.create(:address => email)
        when email_addresses_attributes
          # add email addresses attributes
          user.email_addresses_attributes = email_addresses_attributes
          user.save
        end
      end
      # send user account created
      Delayed::Job.enqueue(UserJob.new(:id => user.id, :password => password, :method => 'send_account_created'))
    end

    user
  end

  def self.create_rpx(name, email, identifier)
    User.transaction do
      # create user in passive state
      user  = self.create(:name => name, :rpx => 1)
      # add email address with rpx identifier
      email = user.email_addresses.create(:address => email, :identifier => identifier)
      # change email state to verfied
      email.verify!
      user
    end
  end
  
  def self.generate_password(length=6)
    chars    = 'abcdefghjkmnpqrstuvwxyzABCDEFGHJKLMNOPQRSTUVWXYZ23456789'
    password = ''
    length.times { |i| password << chars[rand(chars.length)] }
    password
  end

  # def email=(value)
  #   write_attribute :email, (value ? value.downcase : nil)
  # end

  # the special user 'anyone'
  def self.anyone
    r = User.new do |o|
      o.name = "Anyone"
      o.send(:id=, 0)
    end
  end
  
  # return true if its the special user 'anyone'
  def anyone?
    self.id == 0
  end
  
  def email_address
    @email_address ||= self.email_addresses_count > 0 ? self.primary_email_address.address : ''
  end

  def phone_number
    @phone_number ||= self.phone_numbers_count > 0 ? self.primary_phone_number.address : ''
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

end
