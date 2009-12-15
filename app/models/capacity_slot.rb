# Migration is:
# create_table :capacity_slots do |t|
# t.references    :free_appointment, :classname => "Appointment"
# t.datetime      :start_at
# t.datetime      :end_at
# t.integer       :duration
# t.integer       :capacity
# t.integer       :time_start_at    # for time of day searches
# t.integer       :time_end_at
# end
# 
class CapacitySlot < ActiveRecord::Base
  
  belongs_to                  :free_appointment, :class_name => "Appointment"
  
  validates_presence_of       :start_at, :end_at, :duration
  validates_numericality_of   :duration, :greater_than_or_equal_to => 0
  validates_numericality_of   :capacity, :greater_than => 0

  # This must be before validation, as it makes attributes that are required
  before_validation           :make_duration_time_start_end


  named_scope :duration_gt,   lambda { |t|  { :conditions => ["`capacity_slots`.`duration` >= ?", t] }}
  
  named_scope :capacity_gt,   lambda { |c| { :conditions => ["`capacity_slots`.`capacity` > ?", c]}}
  named_scope :capacity_gteq, lambda { |c| { :conditions => ["`capacity_slots`.`capacity` >= ?", c]}}

  # find capacity slots based on a named time range, use lambda to ensure time value is evaluated at run-time
  named_scope :future,        lambda { { :conditions => ["`capacity_slots`.`start_at` >= ?", Time.now] } }
  named_scope :past,          lambda { { :conditions => ["`capacity_slots`.`end_at` <= ?", Time.now] } }

  # find capacity slots overlapping a start and end time
  named_scope :overlap,       lambda { |start_at, end_at|{ :conditions => ["(`capacity_slots`.start_at < ? AND `capacity_slots`.end_at > ?) OR
                                                                            (`capacity_slots`.start_at < ? AND `capacity_slots`.end_at > ?) OR 
                                                                            (`capacity_slots`.start_at >= ? AND `capacity_slots`.end_at <= ?)", 
                                                                            start_at, start_at, end_at, end_at, start_at, end_at] }}

  # find capacity slots overlapping a start and end time, include those which touch the start or end times
  named_scope :overlap_incl,  lambda { |start_at, end_at| { :conditions => ["(`capacity_slots`.start_at < ? AND `capacity_slots`.end_at >= ?) OR
                                                                             (`capacity_slots`.start_at <= ? AND `capacity_slots`.end_at > ?) OR 
                                                                             (`capacity_slots`.start_at >= ? AND `capacity_slots`.end_at <= ?)", 
                                                                             start_at, start_at, end_at, end_at, start_at, end_at] }}
                                                                             
  named_scope :abuts_before, lambda { |start_at| {:conditions => ["capacity_slots.end_at = ?", start_at]}}
  named_scope :abuts_after, lambda { |end_at| {:conditions => ["capacity_slots.start_at = ?", end_at]}}

  # find capacity slots covering the entire time between a start and end time
  named_scope :covers,       lambda { |start_at, end_at|{ :conditions => ["(`capacity_slots`.start_at <= ? AND `capacity_slots`.end_at >= ?)", 
                                                                           start_at, end_at] }}


  # find capacity slots covering a time of day range (i.e. the entire time range is contained within the capacity slot)
  # This needs to account for situations where the end time is the next day, and so is earlier than the start time
  # The first clause deals with the normal situation where the time slot is during a single day
  # The second clause checks if the end time is earlier than the start time. If so, it checks if any one of the following have occurred:
  # - The start and end time are later than the start time
  # - The start and end time are earlier than the end time
  named_scope :time_covers,  lambda { |time_range| if (time_range.blank?)
                                                     {}
                                                   else
                                                     { :conditions => ["((`capacity_slots`.time_start_at <= `capacity_slots`.time_end_at) AND 
                                                                         (`capacity_slots`.time_start_at <= ?) AND (`capacity_slots`.time_end_at >= ?) AND
                                                                         (`capacity_slots`.time_start_at <= ?) AND (`capacity_slots`.time_end_at >= ?)
                                                                        )
                                                                        OR
                                                                        (
                                                                         (`capacity_slots`.time_end_at < `capacity_slots`.time_start_at) AND 
                                                                         (
                                                                          ((`capacity_slots`.time_start_at <= ?) AND (`capacity_slots`.time_start_at <= ?)) OR
                                                                          ((`capacity_slots`.time_end_at >= ?) AND (`capacity_slots`.time_end_at >= ?)) OR
                                                                          ((`capacity_slots`.time_start_at <= ? AND `capacity_slots`.time_end_at >= ?))
                                                                         )
                                                                        )",
                                                                        # For the first clause:
                                                                        time_range.time_start_at_utc.to_i, time_range.time_end_at_utc.to_i,
                                                                        time_range.time_end_at_utc.to_i, time_range.time_start_at_utc.to_i,
                                                                        # For the second clause:
                                                                        time_range.time_start_at_utc.to_i, time_range.time_end_at_utc.to_i,
                                                                        time_range.time_start_at_utc.to_i, time_range.time_end_at_utc.to_i,
                                                                        time_range.time_start_at_utc.to_i, time_range.time_end_at_utc.to_i
                                                                        ] }
                                                   end
                                    }

  named_scope :service,         lambda { |o| { :include => :free_appointment,
                                               :conditions => ["appointments.service_id = ?", o.is_a?(Integer) ? o : o.id] }
                                       }
                                       
  named_scope :provider,        lambda { |provider| if (provider)
                                                      { :include => :free_appointment,
                                                        :conditions => ["appointments.provider_id = ? AND appointments.provider_type = ?", 
                                                                        provider.id, provider.class.to_s]}
                                                    else
                                                      {}
                                                    end
                                       }

  # general_location is used for broad searches, where a search for appointments in Chicago includes appointments assigned to anywhere
  # as well as those assigned to chicago. A search for appointments assigned to anywhere includes all appointments - no constraints.
  named_scope :general_location,
               lambda { |location|
                 if (location.nil? || location.id == 0 || location.id.blank?)
                   # If the request is for any location, there is no condition
                   {}
                 else
                   # If a location is specified, we accept appointments with this location, or with "anywhere" - i.e. null location
                   { :include => :free_appointment, :conditions => ["appointments.location_id = '?' OR appointments.location_id IS NULL", location.id] }
                 end
               }
  # specific_location is used for narrow searches, where a search for appointments in Chicago includes only those appointments assigned to
  # Chicago. A search for appointments assigned to anywhere includes only those appointments - not those assigned to Chicago, for example.
  named_scope :specific_location,
               lambda { |location|
                 # If the request is for any location, there is no condition
                 if (location.nil? || location.id == 0 || location.id.blank? )
                   { :include => :free_appointment, :conditions => ["appointments.location_id IS NULL"] }
                 else
                   # If a location is specified, we accept appointments with this location, or with "anywhere" - i.e. null location
                   { :include => :free_appointment, :conditions => ["appointments.location_id = '?'", location.id] }
                 end
               }
               
  # order by start_at
  named_scope :order_start_at, {:order => 'start_at'}
  
  # order by capacity
  named_scope :order_capacity_desc, {:order => 'capacity DESC'}
  named_scope :order_capacity_asc, {:order => 'capacity ASC'}
  
  
  
  # Class method to merge additional capacity, or create a new capacity slot, as appropriate
  def self.merge_or_add(free_appointment, options = {})
    options ||= {}

    # We require the free appointment we're working with
    if free_appointment.mark_as != Appointment::FREE
      raise ArgumentError
    end

    #
    # First figure out what the start and end times are for the slot we're trying to fill
    #
    new_start_at = new_end_at = new_capacity = nil

    if free_appointment && !options[:work_appointment] && options[:start_at].blank? && options[:end_at].blank?
      # If we aren't given a work appointment, start_at and end_at options, we assume we're to create capacity directly corresponding to the free appointment
      new_start_at = free_appointment.start_at.utc
      new_end_at   = free_appointment.end_at.utc
      new_capacity = options[:capacity].blank? ? free_appointment.capacity : options[:capacity]

    elsif options[:work_appointment]
      # If we're given a work appointment, we assume it's being cancelled and we should create capacity to replace it
      new_start_at = options[:work_appointment].start_at.utc
      new_end_at   = options[:work_appointment].end_at.utc
      new_capacity = options[:capacity].blank? ? options[:work_appointment].capacity : options[:capacity] 
      
    elsif options[:start_at] && options[:end_at]
      new_start_at = options[:start_at].utc
      new_end_at   = options[:end_at].utc
      new_capacity = options[:capacity].blank? ? 1 : options[:capacity]
    else
      raise ArgumentError
    end

    # Calculate the duration for the new timeslot
    new_duration = new_end_at.utc - new_start_at.utc

    # Find the capacity slot attached to this free appointment with the most capacity covering the range.
    max_slot = free_appointment.capacity_slots.covers(new_start_at, new_end_at).order_capacity_desc.first
    affected_slots = free_appointment.capacity_slots

    # If we didn't find a slot, create one with zero capacity - we will then increase it's capacity, along with knock-on impacts
    if max_slot.nil?
      max_slot = free_appointment.capacity_slots.new(:free_appointment => free_appointment, 
                                          :start_at => new_start_at.utc, :end_at => new_end_at.utc,
                                          :duration => new_duration, :capacity => 0)
    end
    
    # increase the slot's capacity
    max_slot.increase_capacity(new_start_at, new_end_at, new_capacity, affected_slots)

    # Make sure the slot we just changed is in the affected_slots array
    affected_slots.push(max_slot).uniq!
    affected_slots.compact!

    #
    # commit the capacity slot changes in a single transaction if required
    #
    CapacitySlot.transaction do
              
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

  end
  
  #
  # Reduce the capacity of this slot by a requested amount during a specific timeframe.
  # This function applies knock-on impacts on other slots, but does not merge or defrag.
  # If this slot is larger than the required timeframe, it will create new slots with the current capacity before
  # and/or after the current slot as appropriate, and reduce the current slot's capacity.
  # The function updates the array of affected slots. If commit is true, the changes are written to the database.
  #
  def reduce_capacity(start_at, end_at, capacity_change, affected_slots, options = {})

    # If this timeslot isn't relevant to us, or if there's no change in capacity, we just return. We shouldn't have been called, but we allow it to happen.
    return if ((self.start_at.utc > end_at.utc) || (self.end_at.utc < start_at.utc)) || (capacity_change == 0)

    # If we're removing capacity and we can't accomodate the capacity requested we raise an exception
    raise AppointmentInvalid, "Not enough capacity available" if ((capacity_change < 0) && (self.capacity < capacity_change))

    # Get the index of self in the affected slots array, assuming it's there. We'll update it at the end
    self_index      = affected_slots.index(self)

    # Remember if we're to commit or not. Later we'll be changing this option
    commit          = options[:commit]

    # Initialize the new before and after slot references
    new_before_slot = new_after_slot  = nil

    # When decreasing the capacity, we create before and after slots, as appropriate, which maintain the current capacity
    if (self.start_at.utc < start_at.utc)
      # This slot covers part of a time range earlier than the request.
      # Create a new capacity slot starting at this slots start time, ending at the time range's start time, with the current capacity
      # Changes will be committed below if required. This new slot will touch, but not overlap, the requested range
      new_before_slot = CapacitySlot.new(:free_appointment => self.free_appointment, :start_at => self.start_at.utc, :end_at => start_at.utc, :capacity => self.capacity)
      self.free_appointment.capacity_slots.push(new_before_slot)
    end
  
    if (self.end_at.utc > end_at.utc)
      # This slot covers part of a time range later than the request.
      # Create a new capacity slot starting at the time range's end time, ending at this slots end time, with the current capacity
      # Changes will be committed below if required. This new slot will touch, but not overlap, the requested range
      new_after_slot = CapacitySlot.new(:free_appointment => self.free_appointment, :start_at => end_at.utc, :end_at => self.end_at.utc, :capacity => self.capacity)
      self.free_appointment.capacity_slots.push(new_after_slot)
    end

    # Adjust this capacity slot by changing its capacity, to zero if appropriate
    new_capacity                        = self.capacity - capacity_change    
    self.capacity                       = new_capacity
    affected_slots[self_index].capacity = new_capacity unless self_index.nil?
      

    # If any other capacity slots overlap this one they need to have their capacity altered also. 
    # Note that these impacted slots do not need to cover the full time range, but they need to cover some of it
    # (i.e. don't use the incl form of the overlap test). 

    # We will commit the changes, or our caller will, so instruct the recursive calls not to commit
    options[:commit] = false

    # Figure out the minimum capacity
    # If we were passed the minimum capacity by our caller, we use that. Otherwise the min capacity is our (adjusted) capacity
    if (options[:minimum_capacity])
      min_capacity = options[:minimum_capacity]
    else
      min_capacity = options[:minimum_capacity] = self.capacity
    end
    
    affected_slots.each do |slot|
      # When reducing capacity, overlapping slots should never be pushed below the level of this slot.
      # They should be reduced by the capacity, but never to less than this slot's capacity
      if (slot != self) && (slot.overlaps_range?(start_at, end_at)) && (slot.capacity > self.capacity)
        slot_capacity_change = (slot.capacity - self.capacity < capacity_change) ? (slot.capacity - self.capacity) : capacity_change
        slot.reduce_capacity(start_at, end_at, slot_capacity_change, affected_slots, options)
      end
    end
    
    # We now add the earlier slots into the list for saving, if required. They don't overlap, so no need to do this until after the above loop.
    # No need to check uniq! as this is a new slot
    affected_slots.push(new_before_slot) unless new_before_slot.nil?
    affected_slots.push(new_after_slot) unless new_after_slot.nil?
    
    # Should be no nil entries here, but just in case
    affected_slots.compact!
    
    #
    # commit the capacity slot changes in a single transaction if required
    #
    if commit
      CapacitySlot.transaction do
                
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
      self.free_appointment.reload
    end

  end
  
  #
  # Increase the capacity of this slot by a requested amount during a specific timeframe.
  # This function applies knock-on impacts on other slots, but does not merge or defrag.
  # If this slot is larger than the required timeframe, it will create a new slot with the new capacity during
  # the current slot as appropriate.
  # The function updates the array of affected slots. If commit is true, the changes are written to the database.
  #
  def increase_capacity(start_at, end_at, capacity_change, affected_slots, options = {})

    # If this timeslot isn't relevant to us, or if there's not change in capacity, we just return. We shouldn't have been called, but we allow it to happen.
    return if ((self.start_at.utc > end_at.utc) || (self.end_at.utc < start_at.utc)) || (capacity_change == 0)

    free_appt_capacity = self.free_appointment.capacity

    # If we're removing capacity and we can't accomodate the capacity requested we raise an exception
    raise AppointmentInvalid, "Too much capacity returned" if (self.capacity + capacity_change > free_appt_capacity)

    # Get the index of self in the affected slots array, assuming it's there. We'll update it at the end
    self_index      = affected_slots.index(self)

    # Remember if we're to commit or not. Later we'll be changing this option
    commit          = options[:commit]

    # Initialize the new center slot reference
    new_center_slot = nil

    # When increasing the capacity of the slot, we figure out if it is exactly the same range as the increase, and if so increase the slot capacity
    if (self.start_at.utc == start_at.utc) && (self.end_at.utc == end_at.utc)
      # Adjust this capacity slot by changing its capacity. Very important to do this in the affected_slots array also.
      new_capacity                        = self.capacity + capacity_change    
      self.capacity                       = new_capacity
      affected_slots[self_index].capacity = new_capacity unless self_index.nil?
    else
      # Otherwise we create a new slot matching the range, with the current slots capacity added to the released capacity
      new_center_slot = CapacitySlot.new(:free_appointment => self.free_appointment, :start_at => start_at.utc, :end_at => end_at.utc, :capacity => self.capacity + capacity_change)
    end

    # If any other capacity slots overlap this one they need to have their capacity altered also. 
    # Note that these impacted slots do not need to cover the full time range, but they need to cover some of it
    # (i.e. don't use the incl form of the overlap test). 

    # We will commit the changes, or our caller will, so instruct the recursive calls not to commit
    options[:commit] = false

    # When increasing capacity we increase the capacity of all overlapping slots during this period of time, except for self (with a check) and the new slot (which isn't 
    # in the affected_slots array yet)
    # First find out the maximum capacity for this time slot. We should never exceed this
    if (options[:maximum_capacity])
      max_capacity = options[:maximum_capacity]
    else
      max_capacity = options[:maximum_capacity] = free_appt_capacity
    end
    
    affected_slots.each do |slot|
      # We will commit the changes, or our caller will, so instruct the recursive call not to commit
      if (slot != self) && (slot.overlaps_range?(start_at, end_at)) && (max_capacity > slot.capacity)
        # When increasing capacity, we need to ensure we don't go above the max capacity for the appointment
        slot_capacity_change = (max_capacity - slot.capacity < capacity_change) ? (max_capacity - slot.capacity) : capacity_change
        slot.increase_capacity(start_at, end_at, slot_capacity_change, affected_slots, options)
      end
    end
    
    # We now add the earlier center slot into the list for saving, if required.
    # No need to check uniq! as this is a new slot
    affected_slots.push(new_center_slot) unless new_center_slot.nil?
    
    # Should be no nil entries here, but just in case
    affected_slots.compact!
    
    #
    # commit the capacity slot changes in a single transaction if required
    #
    if commit
      CapacitySlot.transaction do
                
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
      self.free_appointment.reload
    end

  end

  # Defrag an array of capacity slots
  #
  # If we assume that the array was defragged before a change is made, and then record all the changes, we can optimize by starting to check only the changed slots.
  # There may be knock on impacts as a result of defragging this slot, but at least initially we can reduce the number of slots we check
  #
  def self.defrag(affected_slots)
    
    # We check each of the changed slots to see if any of them should be merged with an existing slot
    # We keep going until no defrag operations happen, as one run through can lead to additional defrags. Initialize defrags to ensure we do the loop at least once
    defrags = true
    max_loop_count = 100
    while (defrags && max_loop_count > 0)
      
      # No defrags done so far
      defrags = false

      # Decrement the max loop count - avoid hangs. Just in case...
      max_loop_count -= 1

      # Check each of the potentially affected slots
      affected_slots.each do |a_slot|

        # Compare these with all other potentially affected slots
        affected_slots.each do |b_slot| 

          # Make sure we're not comparing a slot with itself, and that we're not looking at removed slots
          if (b_slot != a_slot) && (a_slot.capacity > 0) && (b_slot.capacity > 0)
          
            # If the two slots have different capacities, and the smaller capacity is entirely covered by the larger capacity, we have no need of the smaller capacity slot
            if (a_slot.capacity > b_slot.capacity) && (a_slot.covers_incl?(b_slot))

              b_slot.capacity = 0
              defrags = true

            elsif (b_slot.capacity > a_slot.capacity) && (b_slot.covers_incl?(a_slot))

              a_slot.capacity = 0
              defrags = true

            # If the two slots overlap in any way, including touching
            elsif (a_slot.overlaps_incl?(b_slot))

              # if they have the same capacity we get rid of one and have the range of the other cover them both
              if (a_slot.capacity == b_slot.capacity)

                # change the a_slot, remove the b_slot (by setting capacity to 0). The a_slot capacity doesn't change
                a_slot.start_at = (a_slot.start_at <= b_slot.start_at) ? a_slot.start_at : b_slot.start_at
                a_slot.end_at   = (a_slot.end_at >= b_slot.end_at) ? a_slot.end_at : b_slot.end_at
                b_slot.capacity = 0

                defrags = true

              # if the two slots have different capacities, and they overlap (but one does not cover the other) then 
              # we can extend the smaller slot's range to include that of the larger. we don't change the larger capacity slot
              elsif (a_slot.capacity > b_slot.capacity)
                b_slot.start_at = (a_slot.start_at < b_slot.start_at) ? a_slot.start_at : b_slot.start_at
                b_slot.end_at   = (a_slot.end_at > b_slot.end_at) ? a_slot.end_at : b_slot.end_at

                defrags = true
              elsif (b_slot.capacity > a_slot.capacity)
                a_slot.start_at = (a_slot.start_at <= b_slot.start_at) ? a_slot.start_at : b_slot.start_at
                a_slot.end_at   = (a_slot.end_at >= b_slot.end_at) ? a_slot.end_at : b_slot.end_at

                defrags = true
              end

            end

          end
        
        end
        
      end

    end
    
    #
    # commit the capacity slot changes in a single transaction
    #
    CapacitySlot.transaction do
              
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

  end
  
  # A slot overlaps another if it starts before the second finishes, and finishes after the second starts
  # This version includes appointments that touch this appointment
  def overlaps_incl?(slot)
    (self.start_at <= slot.end_at) && (self.end_at >= slot.start_at)
  end
  
  # A slot overlaps another if it starts before the second finishes, and finishes after the second starts
  # This version does not include appointments that touch this appointment
  def overlaps?(slot)
    (self.start_at < slot.end_at) && (self.end_at > slot.start_at)
  end
  
  def overlaps_range_incl?(start_at, end_at)
    (self.start_at <= end_at) && (self.end_at >= start_at)
  end
  
  def overlaps_range?(start_at, end_at)
    (self.start_at < end_at) && (self.end_at > start_at)
  end

  # This slot covers another if its entire time period are between my start and end time
  # This version includes appointments that touch this appointment
  def covers_incl?(slot)
    (self.start_at <= slot.start_at && self.end_at >= slot.end_at)
  end

  # This slot covers another if its entire time period are between my start and end time
  # This version does not include appointments that touch this appointment
  def covers?(slot)
    (self.start_at < slot.start_at && self.end_at > slot.end_at)
  end

  # This version includes appointments that touch this appointment
  def covers_range_incl?(start_at, end_at)
    (self.start_at <= start_at && self.end_at >= end_at)
  end

  protected

  # Assign duration, time_start_at and time_end_at if required
  def make_duration_time_start_end
    # We can't do anything if we don't have a start and end time
    return if self.start_at.nil? || self.end_at.nil?

    # We don't do any work unless the relevant attributes have changed or if it's a new record
    if self.start_at_changed? || self.end_at_changed? || self.new_record?
      # We're going to change time_start_at, time_end_at and duration. Mark these attributes as dirty
      time_start_at_will_change!
      time_end_at_will_change!
      duration_will_change!

      tr                 = TimeRange.new(:start_at => self.start_at, :end_at => self.end_at, :duration => self.duration)
      self.time_start_at = tr.time_start_at_utc
      self.time_end_at   = tr.time_end_at_utc
      self.duration      = tr.duration
    end
  end
  
end
