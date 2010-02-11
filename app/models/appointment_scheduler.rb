class AppointmentScheduler
  
  def self.find_free_appointments(company, location, provider, service, duration, daterange, options={})
    raise ArgumentError, "company is required" if company.blank?
    raise ArgumentError, "location is required" if location.blank?
    raise ArgumentError, "daterange is required" if daterange.blank?

    # use daterange to build start_at, end_at
    start_at    = daterange.start_at
    end_at      = daterange.end_at

    # use time range if it was specified, default to 'anytime'
    time        = options.has_key?(:time_range) ? date_time_options[:time_range] : 'anytime'
    time_range  = Appointment.time_range(time)

    # Clear the service and provider parameters if we don't need to specify specifics
    service  = nil if service.blank? || service.nothing?
    provider = nil if provider.blank? || provider.anyone?

    # remove appointments in the past?
    keep_old = options.has_key?(:keep_old) ? options[:keep_old] : false
    
    # find free appointments for a specific provider, order by start times
    if (!options[:include_canceled].blank?)
      # Include canceled free appointments
      appointments = company.appointments.provider(provider).overlap(start_at, end_at).time_overlap(time_range).duration_gteq(duration).free.general_location(location).order_start_at
    else
      # Exclude canceled free appointments
      appointments = company.appointments.provider(provider).overlap(start_at, end_at).time_overlap(time_range).duration_gteq(duration).free.not_canceled.general_location(location).order_start_at
    end

    # remove appointments that have ended (when compared to Time.now) unless we're told not to (option :keep_old => true) or appointment providers that do not provide the requested service
    appointments.select { |appt| ((keep_old || (appt.end_at.utc > Time.zone.now.utc)) &&
                                  (service.blank? || service.provided_by?(appt.provider)))
                        }
  end
  
  def self.find_free_capacity_slots(company, location, provider, service, duration, daterange, options={})
    raise ArgumentError, "company is required" if company.blank?
    raise ArgumentError, "location is required" if location.blank?
    raise ArgumentError, "daterange is required" if daterange.blank?

    # use daterange to build start_at, end_at
    start_at     = daterange.start_at
    end_at       = daterange.end_at
    
    # use time range if it was specified
    time_range   = options.has_key?(:time_range) ? options[:time_range] : nil
    
    # Clear the service and provider parameters if we don't need to specify specifics
    service  = nil if service.blank? || service.nothing?
    provider = nil if provider.blank? || provider.anyone?

    # remove appointments in the past?
    keep_old = options.has_key?(:keep_old) ? options[:keep_old] : false
    
    # use the (absolute value of the) capacity requested or the capacity from the service (defaults to nil - all capacities are collected)
    capacity_req = options.has_key?(:capacity) ? options[:capacity].abs : (service.blank? ? nil : service.capacity)
    
    # find free appointments for a specific provider, order by start times
    slots = company.capacity_slots.provider(provider).overlap(start_at, end_at).general_location(location).capacity_gteq(capacity_req).order_start_at
    
    # remove slots that have ended (when compared to Time.zone.now) or appointment providers that do not provide the requested service
    if (!keep_old) || (!service.blank?)
      slots = slots.select { |slot| ((keep_old || (slot.end_at.utc > Time.zone.now.utc)) && (service.blank? || service.provided_by?(slot.provider))) }
    end
    
    slots = CapacitySlot.consolidate_slots_for_capacity(slots, capacity_req)
    
    if !duration.blank?
      slots = slots.select { |slot| (slot.duration >= duration.to_i) }
    end
    
    slots
    
  end
  
  # build collection of all free and work appointments over the specified date range
  def self.find_free_work_appointments(company, location, provider, daterange, appointments=nil)
    company.appointments.provider(provider).free_work.overlap(daterange.start_at, daterange.end_at).general_location(location).order_start_at
  end

  # build collection of all work appointments over the specified date range
  def self.find_work_appointments(company, location, provider, daterange, options = {})
    company.appointments.provider(provider).work.overlap(daterange.start_at, daterange.end_at).general_location(location).order_start_at
  end
  
  # create a free appointment in the specified timeslot
  def self.create_free_appointment(company, location, provider, options)
    raise ArgumentError, "company is required" if company.blank?
    raise ArgumentError, "provider is required" if provider.blank?

    # find company free service
    service = company.free_service
    
    raise AppointmentInvalid, "Could not find 'free' service" if service.blank?
    
    # create the new appointment object
    # Make sure it has company, service, provider and capacity values. These will be overridden by the options parameter
    free_hash         = {:company => company, :service => service, :provider => provider, :capacity => provider.capacity }.merge(options)
    free_appointment  = Appointment.new(free_hash)

    # Make sure that it's valid
    raise AppointmentInvalid, free_appointment.errors.full_messages unless free_appointment.valid?
                      
    # free appointments should not have conflicts
    if free_appointment.conflicts?
      raise TimeslotNotEmpty, 'This time conflicts with existing availability.'
    end

    # Save the free appointment and add capacity in a single transaction
    # Capacity is added in the after create filter on Appointment, make_capacity_slot
    Appointment.transaction do

      free_appointment.save
      raise AppointmentInvalid, free_appointment.errors.full_messages unless free_appointment.valid?
      
    end
    
    free_appointment
  end
  
  # create a work appointment by scheduling the specified appointment in a free timeslot
  # options:
  #  - commit => if true, commit the work and free appointment changes; otherwise, create the objects but don't save them; default is true
  def self.create_work_appointment(company, location, provider, service, duration, customer, date_time_options, options={})
    raise ArgumentError, "You must specify the company" if company.blank?
    raise ArgumentError, "You must specify the provider" if provider.blank?
    raise ArgumentError, "You must specify the service" if service.blank?
    raise ArgumentError, "You must specify the customer" if customer.blank?
    
    # should be a work service
    raise AppointmentInvalid, "This is not a valid service" if service.mark_as != Appointment::WORK
    
    # should be a service provided by the provider
    raise AppointmentInvalid, "This service is not provided by this provider" if !service.provided_by?(provider)

    # if options[:commit] == true, then carry out the capacity changes but don't commit them. By default, commit
    commit = options.has_key?(:commit) ? options[:commit] : true
    
    # if options[:force] == true, then add the appointment regardless of the availability of capacity. By default, do not force add
    # This will be added to the appointment object before saving it
    force = options.has_key?(:force) ? options[:force] : false

    # Create the work appointment. Note the reference to the free_appointment corresponding to the relevant space is assigned below
    work_hash        = {:company => company, :provider => provider, :service => service, :duration => duration, :customer => customer,
                        :capacity => service.capacity }.merge(date_time_options)
    work_hash        = work_hash.merge(:force => force)
    work_appointment = Appointment.new(work_hash)
    
    # Make sure that it's valid. Important to do this because we may not save it below (in the no-commit path)
    raise AppointmentInvalid, work_appointment.errors.full_messages unless work_appointment.valid?
                      
    # If we're to commit the changes, make sure the work_appointment is saved
    if commit

      Appointment.transaction do
        
        # These calls will raise an exception if they fail 
        work_appointment.save
        raise AppointmentInvalid, work_appointment.errors.full_messages unless work_appointment.valid?
        
      end
      
    else
      
      # Check if we have capacity
      if !(CapacitySlot.check_capacity(company, location, provider, work_appointment.start_at, work_appointment.end_at, -work_appointment.capacity))
        raise OutOfCapacity, "Not enough capacity available"
      end
                                      
    end
    
    work_appointment

  end
  

  # cancel an appointment. Set force as appropriate
  def self.cancel_appointment(appointment, force = false)
    raise AppointmentInvalid, "Expected an appointment" if appointment.blank?

    # We always commit a cancel
    Appointment.transaction do
      
      # Tell the appointment if it's allowed to create an overbooked situation or not
      appointment.force = force
      
      # cancel and save work appointment
      appointment.cancel
      appointment.save
      raise AppointmentInvalid, appointment.errors.full_messages unless appointment.valid?
      
    end
    
    appointment

  end

end