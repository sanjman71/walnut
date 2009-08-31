require 'digest/sha1'

class User < ActiveRecord::Base
  include Authentication
  include Authentication::ByPassword
  include Authentication::ByCookieToken
  include Authorization::AasmRoles

  include UserAuthIdentity

  # Badges for authorization
  badges_authorized_user

  validates_format_of       :name,     :with => Authentication.name_regex,  :message => Authentication.bad_name_message, :allow_nil => true
  validates_length_of       :name,     :maximum => 100
  validates_presence_of     :name

  validates_presence_of     :email
  validates_length_of       :email,    :within => 6..100 #r@a.wk
  validates_uniqueness_of   :email,    :case_sensitive => false
  validates_format_of       :email,    :with => Authentication.email_regex, :message => Authentication.bad_email_message

  has_many                  :email_addresses, :as => :emailable, :dependent => :destroy
  has_many                  :phone_numbers, :as => :callable, :dependent => :destroy
  has_one                   :primary_phone_number, :class_name => 'PhoneNumber', :as => :callable, :order => "priority asc"

  has_many                  :subscriptions, :dependent => :destroy
  has_many                  :ownerships, :through => :subscriptions, :source => :company
  
  has_many                  :company_providers, :as => :provider, :dependent => :destroy
  has_many                  :companies, :through => :company_providers, :source => :company

  validates_presence_of       :cal_dav_token
  validates_length_of         :cal_dav_token,   :within => 10..150
  validates_uniqueness_of     :cal_dav_token
  before_validation_on_create :reset_cal_dav_token

  # Preferences
  typed_serialize           :preferences, Hash

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
  attr_accessible :email, :name, :password, :password_confirmation, :identifier

  named_scope               :with_emails, lambda { |s| { :conditions => ["email_addresses_count > 0"] }}
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
    u = find_in_state :first, :active, :conditions => {:email => email} # need to get the salt
    u && u.authenticated?(password) ? u : nil
  end
  
  def email=(value)
    write_attribute :email, (value ? value.downcase : nil)
  end

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

  # format phone by removing all non-digits
  def format_phone
    self.phone.gsub!(/[^\d]/, '') unless self.phone.blank?
  end
  
  def manage_user_roles
    unless self.has_role?('user manager', self)
      # all users can manage themselves
      self.grant_role('user manager', self)
    end

    if defined?(ADMIN_USER_EMAILS) and ADMIN_USER_EMAILS.include?(self.email)
      # grant user the 'admin' role
      self.grant_role('admin')
    end
  end
end
