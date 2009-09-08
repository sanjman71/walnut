class BaseJob < Struct.new(:params)

  def send_message_using_message_pub(subject, body, protocol, address)
    logger.debug("*** #{Time.now}: *** sending message pub #{protocol} to: #{address}, subject: #{subject}, body: #{body}")

    # create notification
    notification = MessagePub::Notification.new(:body => body,
                                                :subject => subject,
                                                :escalation => 0,
                                                :recipients => {:recipient => [{:position => 1, :channel => protocol, :address => address}]})
    notification.save
  end

end