class MessageComposeAppointment

  # send all appointment confirmations for the specified appointment
  def self.confirmations(appointment, preferences, options={})
    process('confirmation', appointment, preferences, options)
  end
  
  # send all appointment cancelations for the specified appointment
  def self.cancelations(appointment, preferences, options={})
    process('cancelation', appointment, preferences, options)
  end

  # send appointment reminder to appointment customer
  def self.reminder(appointment)
    process('reminder', appointment, Hash[:customer => 1])
  end

  protected

  # process preferences for sending this appointment message(s)
  def self.process(text, appointment, preferences, options={})
    company   = options[:company]
    messages  = []

    # iterate through each preference
    preferences.keys.each do |key|
      case key
      when :customer
        if preferences[key].to_i == 1
          message = MessageComposeAppointment.send(text, appointment, :customer)
          messages.push([:customer, message]) unless message.blank?
        end
      when :provider
        if preferences[key].to_i == 1
          message = MessageComposeAppointment.send(text, appointment, :provider)
          messages.push([:provider, message]) unless message.blank?
        end
      when :manager
        if preferences[key].to_i == 1 and !company.blank?
          company.authorized_managers.each do |manager|
            message = MessageComposeAppointment.send(text, appointment, :manager, :manager => manager)
            messages.push([:manager, message]) unless message.blank?
          end
        end
      end
    end

    messages
  end

  # send [confirmation, cancelation, reminder] to appointment [customer, provider, or manager]
  def self.send(text, appointment, recipient, options={})
    company   = appointment.company
    provider  = appointment.provider
    customer  = appointment.customer
    manager   = options[:manager]
    sender    = MessageCompose.sender(company)
    message   = nil

    return message if customer.blank? or provider.blank?

    # build message options
    options   = Hash[:template => "appointment_#{text}".to_sym, :topic => appointment, :tag => text, :provider => provider.name,
                     :service => appointment.service.name, :customer => customer.name, :when => appointment.start_at.to_s(:appt_day_date_time)]

    # add customer email, phone
    if customer.email_addresses_count > 0
      options.update(:customer_email => appointment.customer.primary_email_address.address)
    end

    if customer.phone_numbers_count > 0
      options.update(:customer_phone => appointment.customer.primary_phone_number.address)
    end

    # add company, provider footers
    options   = add_footers(company, provider, options)

    # add signature template
    options   = add_signature(options)

    case recipient
    when :customer
      return nil if customer.email_addresses_count == 0
      # send confirm/cancle to appointment customer
      subject   = "[#{company.name}] Appointment #{text}"
      body      = subject
      email     = customer.primary_email_address
      message   = MessageCompose.send(sender, subject, body, [email], options)
    when :provider
      return nil if provider.email_addresses_count == 0
      # send confirm/cancel to appointment provider
      subject   = "[#{company.name}] Appointment #{text}"
      body      = subject
      email     = provider.primary_email_address
      message   = MessageCompose.send(sender, subject, body, [email], options)
    when :manager
      # send confirm/cancel to company manager
      return nil if manager.blank? || manager.email_addresses_count == 0
      subject   = "[#{company.name}] Appointment #{text}"
      body      = subject
      email     = manager.primary_email_address
      message   = MessageCompose.send(sender, subject, body, [email], options)
    end

    return message
  end

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