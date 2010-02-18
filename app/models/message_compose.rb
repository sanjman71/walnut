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

  def self.send(sender, subject, body, recipients, options={})
    topic = options[:topic]
    tag   = options[:tag]
    
    Message.transaction do
      # create message, with preferences
      message = Message.create(:sender => sender, :subject => subject, :body => body)
      [:template, :footers, :signature_template, :provider, :service, :customer, :when].each do |s|
        next if options[s].blank?
        message.preferences[s] = options[s]
      end
      message.save
      # add recipients
      recipients.each do |recipient|
        message.message_recipients.create(:messagable => recipient, :protocol => recipient.protocol)
      end
      if !topic.blank?
        # create message topic
        message.message_topics.create(:topic => topic, :tag => tag)
      end
      # send message
      message.send!

      return message
    end
  end
  
end