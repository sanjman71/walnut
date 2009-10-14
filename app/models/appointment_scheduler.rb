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
      slots = company.capacity_slots.overlap(start_at, end_at).time_covers(time_range).duration_gt(duration).free.general_location(location).capacity_gteq(capacity_req).order_start_at
    else
      # find free appointments for a specific provider, order by start times
      slots = company.capacity_slots.provider(provider).overlap(start_at, end_at).time_covers(time_range).duration_gt(duration).general_location(location).capacity_gteq(capacity_req).order_start_at
    end
    
    # remove slots that have ended (when compared to Time.zone.now) or appointment providers that do not provide the requested service
    slots.select { |slot| slot.end_at.utc > Time.zone.now.utc and service.provided_by?(slot.free_appointment.provider) }
  end
  
  # create a free appointment in the specified timeslot
  def self.create_free_appointment(company, provider, service, options)
    raise ArgumentError, "company is required" if company.blank?
    raise ArgumentError, "provider is required" if provider.blank?
    raise ArgumentError, "service is required" if service.blank?
    
    # find company free service
    service = company.free_service
    
    raise AppointmentInvalid, "Could not find 'free' service" if service.blank?
    
    # create a new appointment object
    # Make sure it has company, service, provider and capacity values. These will be overridden by the options parameter
    free_hash         = {:company => company, :service => service, :provider => provider, :capacity => 1}.merge(options)
    free_appointment  = Appointment.new(free_hash)
                      
    # free appointments should not have conflicts
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
    
    if consume_capacity(work_appointment, max_slot, commit)
      work_appointment
    else
      raise AppointmentInvalid, "No capacity available"
    end
  end
  
  #
  # Consume capacity from a capacity slot, with knock-on implications for other slots
  #
  def self.consume_capacity(work_appointment, max_slot, commit)
    
    # Get all potentially affected capacity slots, and remove capacity from them as appropriate
    affected_slots   = work_appointment.affected_capacity_slots

    # The timeslot we're scheduling
    to_process       = [{:start_at => work_appointment.start_at, :end_at => work_appointment.end_at}]

    # If we were given an eligible slot, we won't get it again
    max_slot         = work_appointment.max_capacity_slot unless max_slot
    
    free_appointment = work_appointment.free_appointment

    #
    # commit the capacity slot changes in a single transaction if required
    #
    if commit
      Appointment.transaction do
                
        if max_slot && max_slot.covers_range_incl?(work_appointment.start_at, work_appointment.end_at) &&
            (max_slot.capacity >= work_appointment.capacity)
          # Reduce the capacity of this slot, and those impacted by this
          max_slot.reduce_capacity(work_appointment.start_at, work_appointment.end_at, work_appointment.capacity, affected_slots, {:commit => false})
          # Now defrag the capacity slots
          CapacitySlot.defrag(affected_slots, false)
        end
    
        # Save the appointments we were handed. This won't happen if they aren't new or dirty
        # This allows the caller to have all of the changes commit in one txn
        work_appointment.save
        free_appointment.save
        
        # enumerate the changed slots
        affected_slots.each do |slot|
          if slot.changed?
            if slot.capacity == 0
              slot.destroy          # Delete those whose capacity is at 0
            else
              slot.save             # Save those with capacity > 0
              if !slot.valid?
                raise ActiveRecord::Rollback
              end
            end
          end
        end
      end
      free_appointment.reload
      
    else

      if max_slot && max_slot.covers_range_incl?(work_appointment.start_at, work_appointment.end_at) &&
          (max_slot.capacity >= work_appointment.capacity)
        # Reduce the capacity of this slot, and those impacted by this
        max_slot.reduce_capacity(work_appointment.start_at, work_appointment.end_at, work_appointment.capacity, affected_slots, {:commit => false})
        # Now defrag the capacity slots
        CapacitySlot.defrag(affected_slots, false)
      end

    end

    true
  end

  # create a waitlist appointment
  # options:
  #  - commit => if true, commit the waitlist appointment; otherwise, create the object but don't save it; default is true
  # def self.create_waitlist_appointment(company, provider, service, customer, date_time_options, options={})
  #   # should be a service that is not marked as work
  #   raise AppointmentInvalid if service.mark_as != Appointment::WORK
  #   
  #   wait_commit       = options.has_key?(:commit) ? options[:commit] : true
  #   wait_hash         = {:company => company, :service => service, :provider => provider, :customer => customer, :mark_as => Appointment::WAIT}.merge(date_time_options)
  #   wait_appointment  = Appointment.new(wait_hash)
  # 
  #   raise AppointmentInvalid if !wait_appointment.valid?
  #   
  #   if wait_commit
  #     # save appointment
  #     wait_appointment.save
  #   end
  #   
  #   wait_appointment
  # end
  
  # split a free appointment into multiple appointments using the specified service and time
  def self.split_free_appointment(appointment, service, duration, service_start_at, service_end_at, options={})
    # validate service argument
    raise ArgumentError if service.blank? or !service.is_a?(Service)
    raise ArgumentError if appointment.service.mark_as != Appointment::FREE

    # check that the current appointment is free
    raise Appointment::AppointmentNotFree if appointment.mark_as != Appointment::FREE
    
    # convert argument Strings to ActiveSupport::TimeWithZones
    service_start_at = Time.zone.parse(service_start_at) if service_start_at.is_a?(String)
    service_end_at   = Time.zone.parse(service_end_at) if service_end_at.is_a?(String)
    
    # time arguments should now be ActiveSupport::TimeWithZone objects
    raise ArgumentError if !service_start_at.is_a?(ActiveSupport::TimeWithZone) or !service_end_at.is_a?(ActiveSupport::TimeWithZone)
        
    # check that the service_start_at and service_end_at times fall within the appointment timeslot
    raise ArgumentError unless service_start_at.between?(appointment.start_at, appointment.end_at) and 
                               service_end_at.between?(appointment.start_at, appointment.end_at)
    
    # build new appointment
    new_appt              = Appointment.new
    new_appt.provider     = appointment.provider
    new_appt.company      = appointment.company
    new_appt.service      = service
    new_appt.start_at     = service_start_at
    new_appt.end_at       = service_end_at
    new_appt.mark_as      = service.mark_as
    new_appt.duration     = duration
    new_appt.customer     = options[:customer]  # set to nil if no customer is specified
    
    # build new start, end appointments
    unless service_start_at == appointment.start_at
      # the start appointment starts at the same time but ends when the new appointment starts
      start_appt          = Appointment.new(appointment.attributes)
      start_appt.start_at = appointment.start_at
      start_appt.end_at   = new_appt.start_at
      start_appt.duration -= duration
    end
    
    unless service_end_at == appointment.end_at
      # the end appointment ends at the same time, but starts when the new appointment ends
      end_appt            = Appointment.new(appointment.attributes)
      end_appt.start_at   = new_appt.end_at
      end_appt.end_at     = appointment.end_at
      end_appt.duration   -= duration
    end
    
    appointments = [start_appt, new_appt, end_appt].compact
    
    if options[:commit]
      
      # commit the apointment changes
      Appointment.transaction do
        # remove the existing appointment first
        appointment.destroy
        
        # add new appointments
        appointments.each do |appointment|
          appointment.save
          if !appointment.valid?
            raise ActiveRecord::Rollback
          end
        end
      end
      
    end
    
    appointments
  end
  
  # cancel the work appointment, and reclaim the necessary free time
  def self.cancel_work_appointment(appointment, options = {})
    raise AppointmentInvalid, "Expected a work appointment" if appointment.blank? or appointment.mark_as != Appointment::WORK

    # find any free time that book-ends this work appointment
    company          = appointment.company
    
    free_appointment = appointment.free_appointment
    if free_appointment.blank?
      raise AppointmentInvalid, "No associated free appointment"
    end
    
    commit = options.has_key?(:commit) ? options[:commit] : false

    if commit
      Appointment.transaction do

        # Create capacity corresponding to the canceled work appointment. We'll commit the changes below.
        affected_slots = CapacitySlot.merge_or_add(free_appointment, false, :work_appointment => appointment)

        # Defrag the capacity slots
        CapacitySlot.defrag(affected_slots)

        # cancel and save work appointment
        appointment.cancel
        appointment.save

        # enumerate the changed slots
        affected_slots.each do |slot|
          if slot.changed?
            if slot.capacity == 0
              slot.destroy          # Delete those whose capacity is at 0
            else
              slot.save             # Save those with capacity > 0
              if !slot.valid?
                raise ActiveRecord::Rollback
              end
            end
          end
        end
      end
      free_appointment.reload
    else
      # Create capacity corresponding to the canceled work appointment. We'll commit the changes below.
      affected_slots = CapacitySlot.merge_or_add(free_appointment, false, :work_appointment => appointment)

      # Defrag the capacity slots
      CapacitySlot.defrag(affected_slots)

      # cancel work appointment
      appointment.cancel

      free_appointment.reload
    end

    free_appointment
  end

  # cancel the wait appointment
  # def self.cancel_wait_appointment(appointment)
  #   raise AppointmentInvalid, "Expected a waitlist appointment" if appointment.blank? or appointment.mark_as != Appointment::WAIT
  #   appointment.cancel
  # end
  
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