class MessageJob < Struct.new(:params)
  def self.priority
    1
  end
  
  def logger
    case RAILS_ENV
    when 'development'
      @logger ||= Logger.new(STDOUT)
    else
      @logger ||= Logger.new("log/messages.log")
    end
  end

  def perform
    logger.info("#{Time.now}: message job: #{params.inspect}")

    message     = Message.find(params[:message_id])
    recipients  = message.message_recipients

    recipients.each do |recipient|
      case recipient.protocol
      when 'email', 'sms'
        send_message_using_message_pub(message, recipient)
      when 'local'
        # local messages are automatically delivered to local recipients
        next
      else
        logger.error("#{Time.now}: [error] ignoring message type #{params[recipient.protocol]}")
      end
    end

    begin
      # track company message statistics
      CompanyMessageDelivery.add(message)
    rescue Exception => e
      logger.error("#{Time.now}: [error] #{e.message}")
    end
  end

  def send_email_using_google(message, recipient)
    subject = message.subject
    body    = message.body

    address = recipient.messagable.address

    logger.debug("#{Time.now}: [message] sending google email to: #{address}, subject: #{subject}, body: #{body}")

    # send email
    UserMailer.deliver_email(address, subject, body)
  end
  
  def send_message_using_message_pub(message, recipient)
    subject = message.subject
    body    = message.body
    
    address = recipient.messagable.address
    channel = recipient.protocol

    logger.debug("#{Time.now}: [message] sending message pub #{channel} to: #{address}, subject: #{subject}, body: #{body}")

    # create notification
    notification = MessagePub::Notification.new(:body => body,
                                                :subject => subject,
                                                :escalation => 0,
                                                :recipients => {:recipient => [{:position => 1, :channel => channel, :address => address}]})
    notification.save

    begin
      # change recipient state to sent
      recipient.sent!
    rescue
    end
  end
end