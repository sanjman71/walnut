class Invitation < ActiveRecord::Base
  include Authentication
  
  # has a sender and a recipient; both are users
  belongs_to              :sender,      :class_name => 'User'
  belongs_to              :recipient,   :class_name => 'User'
  belongs_to              :company
  validates_presence_of   :recipient_email
  validates_format_of     :recipient_email, :with => Authentication.email_regex, :message => Authentication.bad_email_message
  before_create           :generate_token
  
  named_scope             :with_company,    lambda { |o| { :conditions => {:company_id => o.respond_to?(:id) ? o.id : o} } }
  named_scope             :with_sender,     lambda { |o| { :conditions => {:sender_id => o.respond_to?(:id) ? o.id : o} } }

  def claimed?
    # claimed if there is a recipient or there is a user with the recipient email
    return true if !recipient.blank? or !EmailAddress.with_emailable_user.with_address(self.recipient_email).empty?
    false
  end

  private
  
  def generate_token
    self.token = User.make_token
  end

end