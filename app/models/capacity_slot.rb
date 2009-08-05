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

  # This must be before validation, as it makes attributes that are required
  before_validation           :make_duration_time_start_end


  named_scope :future,        lambda { { :conditions => ["`capacity_slots`.start_at >= ?", Time.now.beginning_of_day.utc] } }
  named_scope :past,          lambda { { :conditions => ["`capacity_slots`.start_at < ?", Time.now.beginning_of_day.utc - 1.day] } } # be conservative

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


  # find capacity slots overlapping a time of day range
  named_scope :time_overlap,  lambda { |time_range| if (time_range.blank?)
                                                      {}
                                                    else
                                                      { :conditions => ["(`capacity_slots`.time_start_at < ? AND `capacity_slots`.time_end_at > ?) OR
                                                                         (`capacity_slots`.time_start_at < ? AND `capacity_slots`.time_end_at > ?) OR
                                                                         (`capacity_slots`.time_start_at >= ? AND `capacity_slots`.time_end_at <= ?)",
                                                                         time_range.time_start_at_utc, time_range.time_start_at_utc,
                                                                         time_range.time_end_at_utc, time_range.time_end_at_utc,
                                                                         time_range.time_start_at_utc, time_range.time_end_at_utc] }
                                                    end
                                     }
                                     

  # find capacity slots covering a time of day range (i.e. the entire time range is contained within the capacity slot)
  named_scope :time_covers,  lambda { |time_range| if (time_range.blank?)
                                                     {}
                                                   else
                                                     { :conditions => ["(`capacity_slots`.time_start_at <= ? AND `capacity_slots`.time_end_at >= ?)",
                                                                        time_range.time_start_at_utc, time_range.time_end_at_utc] }
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
  
  
  
  # Class method to merge additional capacity, or create a new capacity slot, as appropriate
  # TODO - don't create the slots, instead use new and commit in caller
  def self.merge_or_add(free_appointment, commit = nil, options = nil)
    
    options ||= {}

    # We require the free appointment we're working with
    if free_appointment.mark_as != Appointment::FREE
      raise ArgumentError
    end

    # During the function we record the changed slots so that we can save them at the end as required
    changed_slots = []

    #
    # First figure out what the start and end times are for the slot we're trying to fill
    #
    new_start_at = new_end_at = new_capacity = nil

    if free_appointment && !options[:work_appointment] && options[:start_at].blank? && options[:end_at].blank?
      # If we aren't given a work appointment, start_at and end_at options, we assume we're to create capacity directly corresponding to the free appointment
      new_start_at = free_appointment.start_at.utc
      new_end_at = free_appointment.end_at.utc
      new_capacity = free_appointment.capacity

    elsif options[:work_appointment]
      # If we're given a work appointment, we assume it's being cancelled and we should create capacity to replace it
      new_start_at = options[:work_appointment].start_at.utc
      new_end_at = options[:work_appointment].end_at.utc
      new_capacity = options[:work_appointment].capacity
      
    elsif options[:start_at] && options[:end_at]
      new_start_at = options[:start_at].utc
      new_end_at = options[:end_at].utc
      new_capacity = options[:capacity].blank? ? 1 : options[:capacity]
    else
      raise ArgumentError
    end

    # Calculate the duration for the new timeslot
    new_duration = (new_end_at.utc - new_start_at.utc) / 60

    #
    # For now...
    # The following does not implement capacity properly, it just works for capacity of 1
    #

    #
    # Merge the requested capacity slot with any existing slots
    #
    
    # Find any capacity slots bookending this new slot
    slots_before  = free_appointment.capacity_slots.abuts_before(new_start_at)
    slots_after   = free_appointment.capacity_slots.abuts_after(new_end_at)

    # If there's > 1, raise an exception
    raise AppointmentInvalid, "Too many adjacent timeslots" if slots_before.size > 1
    raise AppointmentInvalid, "Too many adjacent timeslots" if slots_after.size > 1

    # Get the before and after slots
    slot_before = slots_before.first || nil
    slot_after = slots_after.first || nil

    #
    # Combine the new request with the existing slots
    #
    if slot_before && slot_after.blank?
      # If we have a slot before, none after
      # Combine the slot before with the new request
      slot_before.end_at = new_end_at
      slot_before.duration = (slot_before.end_at - slot_before.start_at) / 60
      changed_slots << slot_before
    
    elsif slot_after && slot_before.blank?
      # If we have a slot after, none before
      # Combine the slot after with the new request
      slot_after.start_at = new_start_at
      slot_after.duration = (slot_after.end_at - slot_after.start_at) / 60
    
    elsif slot_before && slot_after
      # If we have slots both before and after
      # Change the before slot to include both the new and the after
      # Remove the after slot
      slot_before.end_at = slot_after.end_at
      slot_before.duration = (slot_before.end_at - slot_before.start_at) / 60
      slot_after.capacity = 0
    
    else
      # If we have no slots before or after
      # Make a new slot
      changed_slots << 
      free_appointment.capacity_slots.new(:free_appointment => free_appointment, 
                                          :start_at => new_start_at.utc, :end_at => new_end_at.utc,
                                          :duration => new_duration, :capacity => new_capacity)
    end
    
    #
    # Commit the changed slots as required
    #
    if commit
      CapacitySlot.transaction do
        changed_slots.each do |slot|
          if slot.capacity == 0
            slot.destroy
          else
            slot.save
          end
        end
      end
    end

    changed_slots
  end
  
  #
  # Reduce the capacity of this slot by a requested amount during a specific timeframe.
  # This function doesn't consider knock-on impacts on other slots. It this slot is larger than the required timeframe, it will create new slots
  # with the current capacity before and/or after the current slot as appropriate, and reduce the current slot's capacity.
  # The function returns an array of new or changed slots. Nothing is ever saved.
  #
  def reduce_capacity(start_at, end_at, capacity_to_consume, affected_slots, commit = false)

    # If this timeslot isn't relevant to us, we just return an empty changeset. We shouldn't have been called
    return if ((self.start_at.utc > end_at.utc) || (self.end_at.utc < start_at.utc))

    # If we can't accomodate the capacity requested we raise an exception
    raise AppointmentInvalid, "Not enough capacity available" if self.capacity < capacity_to_consume

    # Get the index of self in the affected slots array, assuming it's there. We'll update it at the end
    self_index      = affected_slots.index(self)
    
    new_before_slot = new_after_slot = nil

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

    # Adjust this capacity slot by reducing its capacity, to zero if appropriate
    new_capacity                        = self.capacity - capacity_to_consume    
    self.capacity                       = new_capacity
    affected_slots[self_index].capacity = new_capacity unless self_index.nil?

    # If any other capacity slots overlap this one they need to have their capacity reduced also. 
    # Note that these impacted slots do not need to cover the full time range, but they need to cover some of it (i.e. don't use the incl form of the overlap test)
    # Overlapping slots should never go below the level of this slot. They should be reduced by the capacity, but never to less than this slot's capacity
    affected_slots.each do |slot|
      # We will commit the changes (or our caller will if this is recursive), so instruct the recursive call not to commit
      if (slot != self) && (slot.overlaps_range?(start_at, end_at)) && (slot.capacity > self.capacity)
        slot.reduce_capacity(start_at, end_at, (slot.capacity - self.capacity < capacity_to_consume) ? (slot.capacity - self.capacity) : capacity_to_consume,
                              affected_slots, false)
      end
      
    end
    
    # We now add the earlier slots into the list for saving, if required
    affected_slots.push(new_before_slot) unless new_before_slot.nil? # Add the new slot to the affected slots. No need to check uniq! as this is a new slot
    affected_slots.push(new_after_slot) unless new_after_slot.nil? # Add the new slot to the affected slots. No need to check uniq! as this is a new slot    
    
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
  def self.defrag(affected_slots, commit = false)
    # Now defrag the capacity slots
    # defragged_slots = []
    
    # We check each of the changed slots to see if any of them should be merged with an existing slot
    # We keep going until no defrag operations happen, as one run through can lead to additional defrags. Initialize defrags to ensure we do the loop at least once
    defrags = true
    while (defrags)
      
      # No defrags done so far
      defrags = false

      # Check each of the potentially affected slots
      affected_slots.each do |c_slot|

        # Compare these with all other potentially affected slots
        affected_slots.each do |a_slot| 

          # Make sure we're not comparing a slot with itself
          if c_slot != a_slot
          
            # If the two slots have the same capacity and they overlap in any way, including touching
            if (c_slot.capacity > 0) && (c_slot.capacity == a_slot.capacity) && (c_slot.overlaps_incl?(a_slot))

              # change the a_slot, remove the c_slot (by setting capacity to 0). The capacity doesn't change
              a_slot.start_at = (a_slot.start_at <= c_slot.start_at) ? a_slot.start_at : c_slot.start_at
              a_slot.end_at   = (a_slot.end_at >= c_slot.end_at) ? a_slot.end_at : c_slot.end_at
              c_slot.capacity = 0

              # Add both slots to the end of the passed in array
              # using concat here modifies the passed-in array
              # defragged_slots.concat([a_slot, c_slot]).uniq!
              defrags = true

              # If the two slots have different capacities, and the smaller capacity is entirely covered by the larger capacity, we have no need of the smaller capacity slot
            elsif (a_slot.capacity > 0) && (c_slot.capacity > a_slot.capacity) && (c_slot.covers_incl?(a_slot))

              a_slot.capacity = 0
              # Add it to the end of the passed in array
              # using push here modifies the passed-in array
              # defragged_slots.push(a_slot).uniq!
              defrags = true

              # If the two slots have different capacities, and the smaller capacity is entirely covered by the larger capacity, we have no need of the smaller capacity slot
            elsif (c_slot.capacity > 0) && (c_slot.capacity < a_slot.capacity) && (a_slot.covers_incl?(c_slot))

              c_slot.capacity = 0
              # Add it to the end of the passed in array
              # using push here modifies the passed-in array
              # defragged_slots.push(c_slot).uniq!
              defrags = true

            end

          end
        
        end
        
      end

    end
    
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

      self.duration = (self.end_at.utc - self.start_at.utc) / 60
      self.time_start_at = self.start_at.utc.hour * 3600 + self.start_at.utc.min * 60
      self.time_end_at = self.time_start_at + (self.duration * 60)
    end
  end
  
end
