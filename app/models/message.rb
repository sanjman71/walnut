class Message < ActiveRecord::Base
  belongs_to              :sender, :class_name => "User"
  validates_presence_of   :body, :sender_id
  has_many                :message_recipients, :dependent => :destroy
  accepts_nested_attributes_for :message_recipients, :allow_destroy => true, :reject_if => proc { |attrs| attrs.all? { |k, v| v.blank? } }
  has_many                :message_threads
  has_one                 :message_thread, :order => 'id DESC'
  has_many                :message_topics
  has_many                :user_topics, :through => :message_topics, :source => :topic, :source_type => 'User'
  has_many                :appointment_topics, :through => :message_topics, :source => :topic, :source_type => 'Appointment'
  has_many                :company_message_deliveries
  has_many                :companies, :through => :company_message_deliveries
  before_destroy          :before_destroy_message
  
  # send message
  def send!
    send_local_messages
    send_remote_messages
  end
  
  # reply to message sender
  def reply(options={})
    @reply_sender   = options[:sender]
    @reply_subject  = options[:subject]
    @reply_body     = options[:body]

    raise ArgumentError, "missing sender" if @reply_sender.blank?
    raise ArgumentError, "missing subject" if @reply_subject.blank?
    raise ArgumentError, "missing body" if @reply_body.blank?

    Message.transaction do
      # create reply message
      @reply_message  = Message.create(:sender => @reply_sender, :subject => @reply_subject, :body => @reply_body)

      # find or create original message thread
      @message_thread = self.message_thread || self.create_message_thread

      # add reply message to the same thread
      @reply_message.create_message_thread(:thread => @message_thread.thread)

      @reply_message
    end
  end

  # TODO: reply to sender and all message recipients
  def reply_all(options={})
    
  end

  protected

  # 'send' messages to local recipients
  def send_local_messages
    # check for recipients with protocol 'local'
    message_recipients.local.each do |recipient|
      # mark message as sent, unread
      recipient.sent!
      recipient.unread!
    end
  end

  # use delayed job to send messages to remote recipients
  def send_remote_messages
    if !self.send_at.blank?
      Delayed::Job.enqueue(MessageJob.new(:message_id => self.id), MessageJob.priority, self.send_at)
    else
      Delayed::Job.enqueue(MessageJob.new(:message_id => self.id), MessageJob.priority)
    end
  end

  protected

  def before_destroy_message
    # not allowed to delete a message with at least one recipeint
    return true if self.message_recipients.empty?
    false
  end

end