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
    logger.info("*** #{Time.now}: message job: #{params.inspect}")

    message     = Message.find(params[:message_id])
    recipients  = message.message_recipients

    recipients.each do |recipient|
      case recipient.protocol
      when 'email'
        send_email(message, recipient)
      when 'inbox'
        next
      else
        logger.error("#{Time.now}: xxx ignoring message type #{params[recipient.message_type]}")
      end
    end
  end

  def send_email(message, recipient)
    address = recipient.email
    subject = message.subject
    body    = message.body

    logger.debug("*** #{Time.now}: *** sending email to: #{address}, subject: #{subject}, body: #{body}")

    # send email
    UserMailer.deliver_email(address, subject, body)
  end
end