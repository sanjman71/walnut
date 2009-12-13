class MessageCompose
  
  # default message sender for the company
  def self.sender(company)
    User.first # fix this
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