class MessageRecipient < ActiveRecord::Base
  belongs_to                :message
  belongs_to                :messagable, :polymorphic => true
  validates_presence_of     :messagable_id, :messagable_type, :protocol
  validates_uniqueness_of   :message_id, :scope => [:messagable_id, :messagable_type]

  after_destroy             :after_destroy_recipient

  # BEGIN acts_as_state_machine
  include AASM

  aasm_column           :state

  aasm_initial_state    :created
  aasm_state            :created
  aasm_state            :sent, :enter => :message_sent
  aasm_state            :unread, :enter => :message_unread
  aasm_state            :read, :enter => :message_read

  aasm_event :sent do
    transitions :to => :sent, :from => [:created]
  end
  
  aasm_event :read do
    transitions :to => :read, :from => [:sent, :unread]
  end

  aasm_event :unread do
    transitions :to => :unread, :from => [:sent, :read]
  end
  # END acts_as_state_machine

  # find messages by protocol
  named_scope :local,           { :conditions => {:protocol => 'local'} }
  named_scope :email,           { :conditions => {:protocol => 'email'} }
  named_scope :sms,             { :conditions => {:protocol => 'sms'} }

  named_scope :for_messagable,  lambda { |o| {:conditions => {:messagable_id => o.id, :messagable_type => o.class.to_s} }}

  # valid, supported protocols
  def self.protocols
    ['local', 'email', 'sms']
  end

  # called when the message is marked as sent
  def message_sent
    self.update_attribute(:sent_at, Time.now)
  end

  # called when the message is marked as unread
  def message_unread

  end

  # called when the message is marked as read
  def message_read

  end

  protected

  def after_destroy_recipient
    # destroy message if there are no message recipients
    if self.message.message_recipients.empty?
      self.message.destroy
    end
  end
end