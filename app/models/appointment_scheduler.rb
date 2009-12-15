class AppointmentScheduler
  
  def self.find_free_appointments(company, location, provider, service, duration, daterange, date_time_options={}, options={})
    raise ArgumentError, "company is required" if company.blank?
    raise ArgumentError, "location is required" if location.blank?
    raise ArgumentError, "provider is required" if provider.blank?
    raise ArgumentError, "service is required" if service.blank?
    raise ArgumentError, "duration is required" if duration.blank?
    raise ArgumentError, "daterange is required" if daterange.blank?

    # use daterange to build start_at, end_at
    start_at    = daterange.start_at
    end_at      = daterange.end_at

    # use time range if it was specified, default to 'anytime'
    time        = date_time_options.has_key?(:time) ? date_time_options[:time] : 'anytime'
    time_range  = Appointment.time_range(time)

    if provider.anyone?
      # find free appointments for any provider, order by start times
      appointments = company.appointments.overlap(start_at, end_at).time_overlap(time_range).duration_gt(duration).free.general_location(location).order_start_at
    else
      # find free appointments for a specific provider, order by start times
      appointments = company.appointments.provider(provider).overlap(start_at, end_at).time_overlap(time_range).duration_gt(duration).free.general_location(location).order_start_at
    end

    # remove appointments that have ended (when compared to Time.now) or appointment providers that do not provide the requested service
    appointments.select { |appt| appt.end_at.utc > Time.now.utc and service.provided_by?(appt.provider) }
  end
  
  def self.find_free_capacity_slots(company, location, provider, service, duration, daterange, options={})
    raise ArgumentError, "company is required" if company.blank?
    raise ArgumentError, "location is required" if location.blank?
    raise ArgumentError, "provider is required" if provider.blank?
    raise ArgumentError, "service is required" if service.blank?
    raise ArgumentError, "duration is required" if duration.blank?
    raise ArgumentError, "daterange is required" if daterange.blank?

    # use daterange to build start_at, end_at
    start_at     = daterange.start_at.utc
    end_at       = daterange.end_at.utc
    
    # use time range if it was specified
    time_range   = options.has_key?(:time_range) ? options[:time_range] : nil
    
    # use the (absolute value of the) capacity requested or the default
    capacity_req = options.has_key?(:capacity) ? options[:capacity].abs : 1
    
    if provider.anyone?
      # find free appointments for any provider, order by start times
      slots = company.capacity_slots.overlap(start_at, end_at).time_covers(time_range).duration_gt(duration).general_location(location).capacity_gteq(capacity_req).order_start_at
    else
      # find free appointments for a specific provider, order by start times
      slots = company.capacity_slots.provider(provider).overlap(start_at, end_at).time_covers(time_range).duration_gt(duration).general_location(location).capacity_gteq(capacity_req).order_start_at
    end
    
    # remove slots that have ended (when compared to Time.zone.now) or appointment providers that do not provide the requested service
    slots.select { |slot| slot.end_at.utc > Time.zone.now.utc and service.provided_by?(slot.free_appointment.provider) }
  end
  
  # create a free appointment in the specified timeslot
  def self.create_free_appointment(company, provider, options)
    raise ArgumentError, "company is required" if company.blank?
    raise ArgumentError, "provider is required" if provider.blank?
    
    # find company free service
    service = company.free_service
    
    raise AppointmentInvalid, "Could not find 'free' service" if service.blank?
    
    # create a new appointment object
    # Make sure it has company, service, provider and capacity values. These will be overridden by the options parameter
    free_hash         = {:company => company, :service => service, :provider => provider, :capacity => 1}.merge(options)
    free_appointment  = Appointment.new(free_hash)
                      
    # free appointments should not have conflicts
    # KILLIAN - Why not?
    if free_appointment.conflicts?
      raise TimeslotNotEmpty
    end
    
    # save appointment
    # commit the capacity changes
    Appointment.transaction do
      free_appointment.save
      free_appointment.capacity_slots.each do |slot|
        if !slot.valid?
          raise ActiveRecord::Rollback
        end
      end
    end
      
    
    raise AppointmentInvalid, free_appointment.errors.full_messages unless free_appointment.valid?
    
    free_appointment
  end
  
  # create a work appointment by scheduling the specified appointment in a free timeslot
  # options:
  #  - commit => if true, commit the work and free appointment changes; otherwise, create the objects but don't save them; default is true
  def self.create_work_appointment(company, provider, service, duration, customer, date_time_options, options={})
    raise ArgumentError, "company is required" if company.blank?
    raise ArgumentError, "provider is required" if provider.blank?
    raise ArgumentError, "service is required" if service.blank?
    raise ArgumentError, "customer is required" if customer.blank?
    
    # should be a work service
    raise AppointmentInvalid if service.mark_as != Appointment::WORK
    
    # should be a service provided by the provider
    raise AppointmentInvalid if !service.provided_by?(provider)

    # Create the work appointment. Note the reference to the free_appointment corresponding to the relevant space is assigned below
    work_hash        = {:company => company, :provider => provider, :service => service, :duration => duration, :customer => customer}.merge(date_time_options)
    work_appointment = Appointment.new(work_hash)
    
    # Determine if there is capacity to accomodate the work appointment. This will also find the appropriate free appointment for the work appointment.
    max_slot         = work_appointment.max_capacity_slot

    # If we can't find capacity, fail
    if max_slot.blank?
      raise AppointmentInvalid, "No capacity available"
    else
      # Otherwise update the work appointment with the corresponding free appointment
      work_appointment.free_appointment = max_slot.free_appointment
    end

    raise AppointmentInvalid if !work_appointment.valid?
    
    # should have exactly 1 free time conflict
    # Note that with capacities we may have additional conflicts with work appointments, but we shouldn't have conflicts with more than one free appointment
    raise TimeslotNotEmpty if work_appointment.free_conflicts.size != 1

    # if options[:commit] == true, then carry out the capacity changes but don't commit them
    commit = options.has_key?(:commit) ? options[:commit] : true

    # We don't try to consume capacity if we're not commiting the changes. There's no point - we checked for capacity before
    if !commit || consume_capacity(work_appointment, max_slot)
      work_appointment
    else
      raise AppointmentInvalid, "No capacity available"
    end
  end
  
  #
  # Consume capacity from a capacity slot, with knock-on implications for other slots
  # This always commits changes, in it's own transaction
  #
  def self.consume_capacity(work_appointment, max_slot)
    
    # Get all potentially affected capacity slots, and remove capacity from them as appropriate
    affected_slots   = work_appointment.affected_capacity_slots

    # The timeslot we're scheduling
    to_process       = [{:start_at => work_appointment.start_at, :end_at => work_appointment.end_at}]

    # If we were given an eligible slot, we won't get it again
    max_slot         = work_appointment.max_capacity_slot unless max_slot
    
    free_appointment = work_appointment.free_appointment

    #
    # commit the capacity slot changes in a single transaction
    #
    Appointment.transaction do

      if max_slot && max_slot.covers_range_incl?(work_appointment.start_at, work_appointment.end_at) &&
          (max_slot.capacity >= work_appointment.capacity)
        # Reduce the capacity of this slot, and those impacted by this
        max_slot.reduce_capacity(work_appointment.start_at, work_appointment.end_at, work_appointment.capacity, affected_slots)
        # Now defrag the capacity slots
        CapacitySlot.defrag(affected_slots)
      end
  
      # Save the appointments we were handed. This won't happen if they aren't new or dirty
      work_appointment.save
      free_appointment.save
      
    end
    free_appointment.reload

    true
  end

  # cancel the work appointment, and reclaim the necessary free time
  def self.cancel_work_appointment(appointment)
    raise AppointmentInvalid, "Expected a work appointment" if appointment.blank? or appointment.mark_as != Appointment::WORK

    # find any free time that book-ends this work appointment
    company          = appointment.company
    
    free_appointment = appointment.free_appointment

    # We always commit a cancel
    Appointment.transaction do

      # If we have a free appointment (the usual case) we add the canceled appointment's capacity back to that appointment
      if !free_appointment.blank?
        # Create capacity corresponding to the canceled work appointment.
        CapacitySlot.merge_or_add(free_appointment, :work_appointment => appointment)

        # Defrag the capacity slots
        CapacitySlot.defrag(free_appointment.capacity_slots)
      else
        affected_slots = []
      end

      # cancel and save work appointment
      appointment.cancel
      appointment.save

    end

    free_appointment.reload unless free_appointment.blank?

    free_appointment
  end

  # build collection of all free and work appointments that have not been canceled over the specified date range
  def self.find_free_work_appointments(company, location, provider, daterange, appointments=nil)
    company.appointments.provider(provider).free_work.overlap(daterange.start_at, daterange.end_at).general_location(location).order_start_at
  end
  
  # build collection of all unscheduled appointments over the specified date range
  # returns a hash mapping dates to a appointment collection
  def self.find_unscheduled_time(company, location, provider, daterange, appointments=nil)
    # find all appointments over the specified daterange, order by start_at
    appointments = appointments || company.appointments.provider(provider).free_work.overlap(daterange.start_at, daterange.end_at).order_start_at
    
    # group appointments by day; note that we use the appt start_at utc value to build the day
    appointments_by_day = appointments.group_by { |appt| appt.start_at.utc.to_s(:appt_schedule_day) }
    
    unscheduled_hash = daterange.inject(Hash.new) do |hash, date|
      # build formatted appointment day string
      day_string        = date.to_s(:appt_schedule_day)

      # start with appointment for the entire day, in utc format
      day_start_at_utc  = Time.zone.parse(day_string).beginning_of_day.utc
      day_end_at_utc    = day_start_at_utc + 1.day
      day_appointment   = Appointment.new(:start_at => day_start_at_utc, :end_at => day_end_at_utc, :mark_as => Appointment::NONE)
      
      # find appointments for the day
      day_appts         = appointments_by_day[day_string] || []
      
      # initialize array value
      hash[day_string]  = Array.new
      
      if day_appts.empty?
        # entire day is unscheduled, add full day appointment in utc format
        hash[day_string].push(day_appointment)
      else
        # note: we can build time ranges like this because the appointments are sorted by start_at times
        
        # the first unscheduled time range is from the start of the day to the start of the first appointment
        first_appt = day_appts.first
        
        if first_appt.start_at.utc > day_start_at_utc
          # add unscheduled at beginning of day, in utc format
          appt_none = Appointment.new(:start_at => day_start_at_utc, :end_at => first_appt.start_at.utc, :mark_as => Appointment::NONE)
          hash[day_string].push(appt_none)
        end
        
        # the next set of unscheduled time ranges is between successive appointments, as long they are not back to back
        day_appts.each_with_index do |appt_i, i|
          appt_j = day_appts[i+1]
          next if appt_j.blank?
          next if appt_i.end_at == appt_j.start_at
          # add unscheduled in middle of day, in utc format
          appt_none = Appointment.new(:start_at => appt_i.end_at.utc, :end_at => appt_j.start_at.utc, :mark_as => Appointment::NONE)
          hash[day_string].push(appt_none)
        end
        
        # the last set of unscheduled time ranges is between the end of the last appointment and the end of the day
        last_appt = day_appts.last
        
        if last_appt.end_at.utc < day_end_at_utc
          # add unscheduled at end of day, in utc format
          appt_none = Appointment.new(:start_at => last_appt.end_at.utc, :end_at => day_end_at_utc, :mark_as => Appointment::NONE)
          hash[day_string].push(appt_none)
        end
      end
      
      hash
    end
    
    unscheduled_hash
  end
  
  # options:
  #  - email => true|false, defaults to false
  #  - sms   => true|false, defaults to false
  # def self.send_confirmation(appointment, options={})
  #   confirmations_sent = 0
  #   
  #   email = options.has_key?(:email) ? options[:email] : false
  #   sms   = options.has_key?(:sms) ? options[:sms] : false
  #   
  #   if email
  #     begin
  #       case appointment.mark_as
  #       when Appointment::WORK
  #         MailWorker.async_send_appointment_confirmation(:id => appointment.id)
  #       end
  #       confirmations_sent += 1
  #       RAILS_DEFAULT_LOGGER.debug("Sent email #{appointment.mark_as} appointment confirmation")
  #     rescue Exception => e
  #       RAILS_DEFAULT_LOGGER.debug("Error sending email confirmation message for your appointment.")
  #     end
  #   end
  #   
  #   if sms
  #     begin
  #       case appointment.mark_as
  #       when Appointment::WORK
  #         SmsWorker.async_send_appointment_confirmation(:id => appointment.id)
  #       end
  #       confirmations_sent += 1
  #       RAILS_DEFAULT_LOGGER.debug("Sent sms #{appointment.mark_as} appointment confirmation")
  #     rescue Exception => e
  #       RAILS_DEFAULT_LOGGER.debug("Error sending sms confirmation message for your appointment - #{e.message}")
  #     end
  #   end
  #   
  #   confirmations_sent
  # end
end