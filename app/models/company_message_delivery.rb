class CompanyMessageDelivery < ActiveRecord::Base
  belongs_to              :company
  belongs_to              :message
  belongs_to              :message_recipient
  
  validates_presence_of   :company_id
  validates_presence_of   :message_id
  validates_presence_of   :message_recipient_id

  named_scope :for_company,     lambda { |o| {:conditions => {"company_message_deliveries.company_id" => o.id} }}
  named_scope :for_protocol,    lambda { |s| {:joins => :message_recipient, :conditions => {"message_recipients.protocol" => s} }}

  # add all messages
  def self.add_all
    added = Message.all.inject(0) do |count, message|
      count += add(message)
      count
    end
    added
  end

  # add the specified message
  # returns the number of messages (with message recipients) added
  def self.add(message)
    # skip import if message already exists
    return 0 if self.find_by_message_id(message.id)

    # find first topic
    message_topic = message.message_topics.first
    return 0 if message_topic.blank?

    company = find_company(message_topic)
    return 0 if company.blank?

    # puts "*** topic: #{message_topic.inspect}"
    # puts "*** company: #{company.inspect}"
    # puts "*** recipients: #{message.message_recipients.size}"

    added = 0
    message.message_recipients.each do |recipient|
      self.create(:company_id => company.id, :message_id => message.id, :message_recipient_id => recipient.id)
      added += 1
    end
    added
  end

  protected

  # find company associated with the message topic
  def self.find_company(message_topic)
    case
    when message_topic.topic.respond_to?(:company)
      # topic has a company
      return message_topic.topic.company
    else message_topic.topic.respond_to?(:user_roles)
      # use badges to find company association
      user_role = message_topic.topic.user_roles.select { |o| o.authorizable_type == Company.to_s }.first
      return user_role.blank? ? nil : user_role.authorizable
    end
  end

end