class Invitation < ActiveRecord::Base
  # has a sender and a recipient, which are both user objects
  belongs_to    :sender,      :class_name => 'User'
  belongs_to    :recipient,   :class_name => 'User'
  belongs_to    :company
  
  validates_presence_of   :recipient_email
  
  before_create           :generate_token
  
  private
  
  def generate_token
    self.token = User.make_token
  end

end