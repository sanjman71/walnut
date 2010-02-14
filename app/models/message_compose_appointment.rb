class MessageComposeAppointment

  def self.confirmations(appointment, preferences, options={})
    preferences = eval(preferences) if preferences.is_a?(String)
    company     = options[:company]
    messages    = []

    # iterate through each preference
    preferences.keys.each do |key|
      case key
      when :customer
        if preferences[key].to_i == 1
          message = MessageComposeAppointment.confirmation(appointment, :customer)
          messages.push([:customer, message]) unless message.blank?
        end
      when :provider
        if preferences[key].to_i == 1
          message = MessageComposeAppointment.confirmation(appointment, :provider)
          messages.push([:provider, message]) unless message.blank?
        end
      when :manager
        if preferences[key].to_i == 1 and !company.blank?
          company.authorized_managers.each do |manager|
            message = MessageComposeAppointment.confirmation(appointment, :manager, :manager => manager)
            messages.push([:manager, message]) unless message.blank?
          end
        end
      end
    end

    messages
  end

  # send confirmation to appointment customer, provider, or manager
  def self.confirmation(appointment, recipient, options={})
    company   = appointment.company
    provider  = appointment.provider
    customer  = appointment.customer
    sender    = MessageCompose.sender(company)
    message   = nil

    return message if customer.blank? or provider.blank?
    
    case recipient
    when :customer
      return nil if customer.email_addresses_count == 0
      # check company, provider email preferences
      text      = [company.preferences[:email_text], provider.preferences[:provider_email_text]].reject(&:blank?).join("\n\n")
      # send confirmation to appointment customer
      subject   = "[#{company.name}] Appointment confirmation"
      body      = "Your appointment with #{provider.name} on #{appointment.start_at.to_s(:appt_day_date_time)} has been confirmed."
      body      += "\n\n#{text}" unless text.blank?
      email     = customer.primary_email_address
      message   = MessageCompose.send(sender, subject, body, [email], appointment, 'confirmation')
    when :provider
      return nil if provider.email_addresses_count == 0
      # send confirmation to appointment provider
      subject   = "[#{company.name}] Appointment confirmation"
      body      = "Customer #{customer.name} has scheduled an appointment with you on #{appointment.start_at.to_s(:appt_day_date_time)}."
      email     = provider.primary_email_address
      message   = MessageCompose.send(sender, subject, body, [email], appointment, 'confirmation')
    when :manager
      # send confirmation to company manager
      manager  = options[:manager]
      return nil if manager.email_addresses_count == 0
      subject   = "[#{company.name}] Appointment confirmation"
      body      = "Your appointment with #{customer.name} on #{appointment.start_at.to_s(:appt_day_date_time)} has been confirmed."
      email     = manager.primary_email_address
      message   = MessageCompose.send(sender, subject, body, [email], appointment, 'confirmation')
    end

    return message
  end

  # send appointment reminder to appointment customer
  def self.reminder(appointment)
    company   = appointment.company
    provider  = appointment.provider
    customer  = appointment.customer
    sender    = MessageCompose.sender(company)

    return nil if customer.blank? or provider.blank?
    return nil if customer.email_addresses_count == 0

    # send reminder to appointment customer
    subject   = "[#{company.name}] Appointment reminder"
    body      = "This is just a reminder that your appointment with #{provider.name} on #{appointment.start_at.to_s(:appt_day_date_time)} is coming up."
    email     = customer.primary_email_address
    message   = MessageCompose.send(sender, subject, body, [email], appointment, 'reminder')

    return message
  end

end