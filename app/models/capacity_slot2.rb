# Migration is:
# create_table :capacity_slot2s do |t|
# t.references    :company
# t.references    :provider
# t.references    :location
# t.datetime      :start_at
# t.datetime      :end_at
# t.integer       :capacity
# end
# 
class CapacitySlot2 < ActiveRecord::Base
  
  belongs_to                  :company
  belongs_to                  :provider, :polymorphic => true
  belongs_to                  :location

  validates_presence_of       :start_at, :end_at, :duration
  validates_numericality_of   :duration, :greater_than => 0
  validates_numericality_of   :capacity

  # This must be before validation, as it makes attributes that are required
  before_validation           :make_duration


  named_scope :provider,      lambda { |provider| (provider.blank?) ? {} : 
                                                    { :conditions => ["`capacity_slot2s`.`provider_id` = ? AND `capacity_slot2s`.`provider_type` = ?", provider.id, provider.class.to_s]} }

  # Duration greater than or equal to a value. If nil passed in here, no conditions are added
  named_scope :duration_gteq, lambda { |t| (t.blank?) ? {} : { :conditions => ["`capacity_slot2s`.`duration` >= ?", t] } }
  
  named_scope :capacity_gt,   lambda { |c| (c.blank?) ? {} : {:conditions => ["`capacity_slot2s`.`capacity` > ?", c]} }
  named_scope :capacity_gteq, lambda { |c| (c.blank?) ? {} : { :conditions => ["`capacity_slot2s`.`capacity` >= ?", c]} }

  # find capacity slots based on a named time range, use lambda to ensure time value is evaluated at run-time
  named_scope :future,        lambda { { :conditions => ["`capacity_slot2s`.`start_at` >= ?", Time.now] } }
  named_scope :past,          lambda { { :conditions => ["`capacity_slot2s`.`end_at` <= ?", Time.now] } }

  # find capacity slots overlapping a start and end time
  named_scope :overlap,       lambda { |start_at, end_at|{ :conditions => ["(`capacity_slot2s`.start_at < ? AND `capacity_slot2s`.end_at > ?) OR
                                                                            (`capacity_slot2s`.start_at < ? AND `capacity_slot2s`.end_at > ?) OR 
                                                                            (`capacity_slot2s`.start_at >= ? AND `capacity_slot2s`.end_at <= ?)", 
                                                                            start_at, start_at, end_at, end_at, start_at, end_at] }}

  # find capacity slots overlapping a start and end time, include those which touch the start or end times
  named_scope :overlap_incl,  lambda { |start_at, end_at| { :conditions => ["(`capacity_slot2s`.start_at < ? AND `capacity_slot2s`.end_at >= ?) OR
                                                                             (`capacity_slot2s`.start_at <= ? AND `capacity_slot2s`.end_at > ?) OR 
                                                                             (`capacity_slot2s`.start_at >= ? AND `capacity_slot2s`.end_at <= ?)", 
                                                                             start_at, start_at, end_at, end_at, start_at, end_at] }}
                                                                             
  named_scope :abuts_before, lambda { |start_at| {:conditions => ["capacity_slot2s.end_at = ?", start_at]}}
  named_scope :abuts_after, lambda { |end_at| {:conditions => ["capacity_slot2s.start_at = ?", end_at]}}

  # find capacity slots covering the entire time between a start and end time
  named_scope :covers,       lambda { |start_at, end_at|{ :conditions => ["(`capacity_slot2s`.start_at <= ? AND `capacity_slot2s`.end_at >= ?)", 
                                                                           start_at, end_at] }}


  # general_location is used for broad searches, where a search for appointments in Chicago includes appointments assigned to anywhere
  # as well as those assigned to chicago. A search for appointments assigned to anywhere includes all appointments - no constraints.
  named_scope :general_location,
               lambda { |location|
                 if (location.nil? || location.id == 0 || location.id.blank?)
                   # If the request is for any location, there is no condition
                   {}
                 else
                   # If a location is specified, we accept appointments with this location, or with "anywhere" - i.e. null location
                   { :conditions => ["location_id = '?' OR location_id IS NULL", location.id] }
                 end
               }
  # specific_location is used for narrow searches, where a search for appointments in Chicago includes only those appointments assigned to
  # Chicago. A search for appointments assigned to anywhere includes only those appointments - not those assigned to Chicago, for example.
  named_scope :specific_location,
               lambda { |location|
                 # If the request is for any location, there is no condition
                 if (location.nil? || location.id == 0 || location.id.blank? )
                   { :conditions => ["location_id IS NULL OR location_id = 0"] }
                 else
                   # If a location is specified, we accept appointments with this location, or with "anywhere" - i.e. null location
                   { :conditions => ["location_id = '?'", location.id] }
                 end
               }
               
  # order by start_at
  named_scope :order_start_at, {:order => 'start_at'}
  # order by capacity
  named_scope :order_capacity_desc, {:order => 'capacity DESC'}
  named_scope :order_capacity_asc, {:order => 'capacity ASC'}
  # combined ordering, first by start_at, then by capacity, larger capacity first
  named_scope :order_start_at_capacity_desc, {:order => 'start_at, capacity DESC'}
  named_scope :order_start_at_capacity_asc, {:order => 'start_at, capacity ASC'}

  #
  # Maintain API from CapacitySlot
  #
  def self.merge_or_add(appointment)
    self.change_capacity(appointment.company, appointment.location, appointment.provider, 
                        appointment.start_at, appointment.end_at, (appointment.free? ? appointment.capacity : -appointment.capacity))
  end

  #
  # Class method to change capacity in a time period
  #
  def self.change_capacity(company, location, provider, start_at, end_at, capacity_change, options = {})
    raise ArgumentError, "You must specify the company" if company.blank?
    raise ArgumentError, "You must specify the provider" if provider.blank?
    raise ArgumentError, "You must specify the start time" if start_at.blank?
    raise ArgumentError, "You must specify the end time" if end_at.blank?
    raise ArgumentError, "You must specify the capacity change" if capacity_change.blank?
    
    # If no capacity change is requested, do nothing
    return if (capacity_change == 0)

    # Determine if we've been asked to force the capacity change
    force = options.has_key?(:force) ? options[:force] : false

    # Find all the affected capacity slots
    affected_slots = company.capacity_slot2s.provider(provider).specific_location(location).overlap_incl(start_at, end_at).order_start_at

    current_time       = start_at
    current_slot_index = 0

    # Carry this out in a transaction
    CapacitySlot2.transaction do
      
      while (current_time < end_at)
        
        current_slot = (current_slot_index < affected_slots.size) ? affected_slots[current_slot_index] : nil
        
        if (current_slot.blank?)

          # We aren't allowed go below 0 if we weren't asked to force
          if (capacity_change < 0) && (!force)
            raise AppointmentInvalid, "Not enough capacity available"
          end
          
          # We've run out of slots. Build a slot from current_time to the end of the request
          CapacitySlot2.create(:company => company, :provider => provider, :location => location, 
                               :start_at => current_time, :end_at => end_at, :capacity => capacity_change)
          
          # Move current time forward to the end of this newly created capacity slot. This will finish the loop.
          current_time = end_at
          
        elsif current_slot.end_at <= current_time
          # The current slot ends before we start. Move onto the next slot.
          # This shouldn't happen
          RAILS_DEFAULT_LOGGER.debug("********* CapacitySlot2: change_capacity: shouldn't reach this point #1")
          current_slot_index += 1
          
        elsif (current_slot.start_at > current_time)
          # The next slot in the list starts later than the current time. We need to make a new slot to fill this gap from current_time until current_slot.start_at
          # Since there is no slot here now, there is capacity 0. The new slot will have capacity set to capacity_change

          # Figure out what time this new slot should end at. Note that it should always be current_slot.start_at, because current_slot shouldn't be in
          # the array if it isn't impacted, i.e. current_slot.start_at should never be > end_at
          if (current_slot.start_at > end_at)
            slot_end_at = end_at
            RAILS_DEFAULT_LOGGER.debug("********* CapacitySlot2: change_capacity: shouldn't reach this point #2")
          else
            slot_end_at = current_slot.start_at
          end

          # We aren't allowed go below 0 if we weren't asked to force
          if (capacity_change < 0) && (!force)
            raise AppointmentInvalid, "Not enough capacity available"
          end

          # Create the new slot
          CapacitySlot2.create(:company => company, :provider => provider, :location => location, 
                               :start_at => current_time, :end_at => slot_end_at, :capacity => capacity_change)

          # Don't move forward the affected_slots index - we haven't processed the current_slot
          # Move forward the current_time
          current_time = slot_end_at
          
        else
          # We know, because of the above tests, that (current_slot.start_at <= current_time) && (current_slot.end_at > current_time)
          
          # Remember the current_slot's original capacity and end time
          orig_capacity = current_slot.capacity
          orig_start_at = current_slot.start_at
          orig_end_at   = current_slot.end_at

          # Change current_slot's start_time, end_time and capacity
          # The new end time is the earlier of end_at and current_slot.end_at
          new_end_at    = (end_at > orig_end_at) ? orig_end_at : end_at
          new_capacity  = current_slot.capacity + capacity_change

          # We aren't allowed go below 0 if we weren't asked to force
          if (capacity_change < 0) && (new_capacity < 0) && (!force)
            raise AppointmentInvalid, "Not enough capacity available"
          end

          # If the current_slot starts before our current_time, we need to create a new slot 
          # from current_slot.start_at to current_time with the current_slot's capacity        
          if (orig_start_at < current_time)

            # Create a new slot from current_slot.start_at to current_time, if necessary. It retains the same capacity as current_slot
            # This new slot occurs earlier than our time of interest (current_time to end_time) and so we don't have to process it again
            CapacitySlot2.create(:company => company, :provider => provider, :location => location, 
                                 :start_at => orig_start_at, :end_at => current_time, :capacity => orig_capacity)

          end

          current_slot.start_at = current_time      # There may be no change here, if current_time == orig_start_at
          current_slot.end_at   = new_end_at        # There may be no change here, if end_at == orig_end_at
          current_slot.capacity = new_capacity      # There will be a change here
          current_slot.save

          # Advance the current time to new_end_at, and advance to the next slot in the impacted list
          current_time = new_end_at
          current_slot_index += 1

          # If we changed the current_slot end_at (i.e. new_end_at != orig_end_at, which implies that new_end_at == end_at)
          if (new_end_at != orig_end_at)

            # We did change the current_slot.end at, because the current_slot ended later than end_at.
            # We need to create a new slot, from the new_end_at to the orig_end_at, with the orig_capacity

            CapacitySlot2.create(:company => company, :provider => provider, :location => location, 
                                 :start_at => new_end_at, :end_at => orig_end_at, :capacity => orig_capacity)

            # At this point current_time == end_at, and we're finished. If not, yell about it!
            if (current_time != end_at)
              RAILS_DEFAULT_LOGGER.debug("********* CapacitySlot2: change_capacity: shouldn't reach this point #3")
            end

          end
          
        end
        
      end
      
      # Consolidate the slots - combine any that abut each other and have the same capacity

      # Find all the affected slots again
      affected_slots = company.capacity_slot2s.provider(provider).specific_location(location).overlap_incl(start_at, end_at).order_start_at

      # Iterate through them, comparing the previous slot with the current one in each case. We start on the second item
      previous_slot = nil

      affected_slots.each do |current_slot|

        # We remove slots with 0 capacity
        if (current_slot.capacity == 0)

          current_slot.destroy
          current_slot = nil
          
        elsif ((!previous_slot.blank?) &&
               (previous_slot.capacity == current_slot.capacity) &&
               (previous_slot.end_at == current_slot.start_at))

          # If the slots abut and have the same capacity, we extend the current_slot to include the previous_slot,
          # and destroy the previous_slot
          current_slot.start_at = previous_slot.start_at
          current_slot.save
          previous_slot.destroy
          
        end

        # Move the current_slot to the previous slot
        previous_slot = current_slot
        
      end
      
    end

  end
  
  def self.check_capacity(company, location, provider, start_at, end_at, capacity_change, options = {})

    raise ArgumentError, "You must specify the company" if company.blank?
    raise ArgumentError, "You must specify the provider" if provider.blank?
    raise ArgumentError, "You must specify the start time" if start_at.blank?
    raise ArgumentError, "You must specify the end time" if end_at.blank?
    raise ArgumentError, "You must specify the capacity change" if capacity_change.blank?

    # Find all the affected capacity slots - don't include those abutting the start and end time
    affected_slots = company.capacity_slot2s.provider(provider).specific_location(location).overlap(start_at, end_at).order_start_at
    
    # iterate through the slots, making sure that they have capacity + capacity_change > 0, and that there are no gaps
    have_capacity = true
    previous_slot = nil
    affected_slots.each do |current_slot|

      # If there's a gap between the previous and current slot, or if the capacity change results in a negative capacity,
      # We do not have capacity
      if ((!previous_slot.blank? && (previous_slot.end_at != current_slot.start_at)) ||
          (current_slot.capacity + capacity_change < 0))
        have_capacity = false
      end
      
      # move the current_slot to the previous slot
      previous_slot = current_slot
      
    end
    
    have_capacity
    
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

  #
  # This function takes an array of capacity slots and returns an array of slots which do not overlap
  # It is assumed that the slots provided have the capacity required.
  # All capacity greater than or equal to the required capacity is treated the same. This is intended for use in
  # displaying the openings available.
  # The array that is returned is for view use only, and must not be saved
  #
  def self.consolidate_slots_for_capacity(slots, capacity_req)

    # If capacity_req wasn't provided, make no changes
    if capacity_req.blank?
      return slots
    end

    case slots.size
    when 0 then
      return slots
    when 1 then
      if (slots.first.capacity >= capacity_req)
        return slots
      else
        return []
      end
    end

    sorted_slots = slots.sort_by {|x| x.start_at }
    
    # Iterate through them, comparing the previous slot with the current one in each case. We start on the second item
    res_slots = []
    res_slot = nil

    sorted_slots.each do |current_slot|

      if (current_slot.capacity >= capacity_req)
        
        if (!res_slot.blank?) && (current_slot.start_at == res_slot.end_at)

          # Change the res_slot end time to encompass the current slot, and modify it's capacity if required
          res_slot.end_at = current_slot.end_at
          res_slot.capacity = current_slot.capacity unless (current_slot.capacity >= res_slot.capacity)
          res_slot.duration += current_slot.duration
          
        else

          # The slots don't abut, so add the previous slot to the results array and start a new res_slot
          res_slots << res_slot unless res_slot.blank?
          res_slot = current_slot
          
        end
        
      else
        # The current slot capacity is too small. We don't do anything here - we just move onto the next slot
      end

    end

    # Store the final res_slot if appropriate
    res_slots << res_slot unless res_slot.blank?
    
    res_slots
      
  end

  # Preserve the API from CapacitySlot
  def self.build_openings_for_view(slots)
    slots
  end
  
  protected

  # Assign duration if required
  def make_duration
    # We can't do anything if we don't have a start and end time
    return if self.start_at.nil? || self.end_at.nil?

    # We don't do any work unless the relevant attributes have changed or if it's a new record
    if self.start_at_changed? || self.end_at_changed? || self.new_record?

      # We're going to change duration. Mark it as dirty
      duration_will_change!
      self.duration      = self.end_at - self.start_at
    end
  end
  
end
