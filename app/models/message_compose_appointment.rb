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
    manager   = options[:manager]
    sender    = MessageCompose.sender(company)
    message   = nil

    return message if customer.blank? or provider.blank?

    # build message options
    options   = Hash[:template => :appointment_confirmation, :topic => appointment, :tag => 'confirmation', :provider => provider.name,
                     :service => appointment.service.name, :customer => customer.name, :when => appointment.start_at.to_s(:appt_day_date_time)]

    # add company, provider footers
    options   = add_footers(company, provider, options)

    # add signature template
    options   = add_signature(options)

    case recipient
    when :customer
      return nil if customer.email_addresses_count == 0
      # send confirmation to appointment customer
      subject   = "[#{company.name}] Appointment confirmation"
      body      = subject
      email     = customer.primary_email_address
      message   = MessageCompose.send(sender, subject, body, [email], options)
    when :provider
      return nil if provider.email_addresses_count == 0
      # send confirmation to appointment provider
      subject   = "[#{company.name}] Appointment confirmation"
      body      = subject
      email     = provider.primary_email_address
      message   = MessageCompose.send(sender, subject, body, [email], options)
    when :manager
      # send confirmation to company manager
      return nil if manager.blank? || manager.email_addresses_count == 0
      subject   = "[#{company.name}] Appointment confirmation"
      body      = subject
      email     = manager.primary_email_address
      message   = MessageCompose.send(sender, subject, body, [email], options)
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

    # build message options
    options   = Hash[:template => :appointment_reminder, :topic => appointment, :tag => 'reminder', :provider => provider.name,
                     :service => appointment.service.name, :customer => customer.name, :when => appointment.start_at.to_s(:appt_day_date_time)]

    # add company, provider footers
    options   = add_footers(company, provider, options)

    # add signature template
    options   = add_signature(options)

    # send reminder to appointment customer
    subject   = "[#{company.name}] Appointment reminder"
    body      = subject
    email     = customer.primary_email_address
    message   = MessageCompose.send(sender, subject, body, [email], options)

    return message
  end

  protected

  # add company and provider footers
  def self.add_footers(company, provider, options)
    options.update(:footer_company => company.preferences[:email_text]) unless (company.blank? or company.preferences[:email_text].blank?)
    options.update(:footer_provider => provider.preferences[:provider_email_text]) unless (provider.blank? or provider.preferences[:provider_email_text].blank?)
    options
  end

  def self.add_signature(options)
    options.update(:signature_template => :signature_general)
  end

end