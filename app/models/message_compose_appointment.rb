class MessageComposeAppointment

  # send appointment confirmation
  def self.confirmation(appointment)
    company   = appointment.company
    provider  = appointment.provider
    customer  = appointment.customer
    sender    = MessageCompose.sender(company)

    return -1 if customer.blank?
    return -1 if customer.email_addresses_count == 0
    
    # send confirmation to appointment customer
    subject   = "[#{company.name}] Appointment confirmation"
    body      = "Your appointment with #{provider.name} on #{appointment.start_at.to_s(:appt_day_date_time)} has been confirmed."
    email     = customer.primary_email_address
    message   = MessageCompose.send(sender, subject, body, [email], appointment, 'confirmation')

    return 0
  end

  # send appointment reminder
  def self.reminder(appointment)
    company   = appointment.company
    provider  = appointment.provider
    customer  = appointment.customer
    sender    = MessageCompose.sender(company)

    return -1 if customer.blank?
    return -1 if customer.email_addresses_count == 0

    # send reminder to appointment customer
    subject   = "[#{company.name}] Appointment reminder"
    body      = "This is just a reminder that your appointment with #{provider.name} on #{appointment.start_at.to_s(:appt_day_date_time)} is coming up."
    email     = customer.primary_email_address
    message   = MessageCompose.send(sender, subject, body, [email], appointment, 'reminder')

    return 0
  end

end