class MessageCompose
  
  # default message sender for the company, user
  def self.sender(object)
    case object.class.to_s.downcase
    when 'company'
      # find first company manager, or first provider
      object.authorized_managers.first || object.authorized_providers.first
    when 'user'
      object
    else
      User.first
    end
  end

  def self.send(sender, subject, body, recipients, topic, tag)
    Message.transaction do
      # create message
      message = Message.create(:sender => sender, :subject => subject, :body => body)
      # add recipients
      recipients.each do |recipient|
        message.message_recipients.create(:messagable => recipient, :protocol => recipient.protocol)
      end
      # send message
      message.send!
      # create message topic
      message.message_topics.create(:topic => topic, :tag => tag)

      return message
    end
  end
  
end