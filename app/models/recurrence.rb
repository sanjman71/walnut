class Recurrence
  
  FREQ = {
    "WEEKLY" => "Weekly"
  }

  DAYS_OF_WEEK = 
    {
      "SU" => "Sunday",
      "MO" => "Monday",
      "TU" => "Tuesday",
      "WE" => "Wednesday",
      "TH" => "Thursday",
      "FR" => "Friday",
      "SA" => "Saturday"
    }

  DAYS_OF_WEEK_INT = 
    {
      "SU" => 0,
      "MO" => 1,
      "TU" => 2,
      "WE" => 3,
      "TH" => 4,
      "FR" => 5,
      "SA" => 6
    }

  # Return the recurrence days from the specified appointment or recurrence rule
  def self.days(appt_or_rule, options={})
    case
    when appt_or_rule.is_a?(Appointment)
      recur_rule = appt_or_rule.recur_rule
    when appt_or_rule.is_a?(String)
      recur_rule = appt_or_rule
    else
      return []
    end
    # check recur_rule before parsing it
    return [] if recur_rule.blank?

    recur_rule =~ /FREQ=([A-Z]*);BYDAY=([A-Z,]*)/i
    freq = FREQ[$1] unless $1.blank?

    # check options
    format = options[:format] ? options[:format] : :short
    case format
    when :short
      days = $2.split(',').map{|d| DAYS_OF_WEEK[d.to_s.upcase][0..2]} unless $2.blank?
    when :long
      days = $2.split(',').map{|d| DAYS_OF_WEEK[d.to_s.upcase]} unless $2.blank?
    when :int
      days = $2.split(',').map{|d| DAYS_OF_WEEK_INT[d.to_s.upcase]} unless $2.blank?
    end
    
    if freq.blank? || days.blank? || days.empty?
      []
    else
      days
    end
  end

  def self.frequency(appt_or_rule)
    case
    when appt_or_rule.is_a?(Appointment)
      recur_rule = appt_or_rule.recur_rule
    when appt_or_rule.is_a?(String)
      recur_rule = appt_or_rule
    else
      return ''
    end
    # check recur_rule before parsing it
    return '' if recur_rule.blank?

    recur_rule =~ /FREQ=([A-Z]*);BYDAY=([A-Z,]*)/i
    freq = FREQ[$1] unless $1.blank?
    freq ? freq.downcase : ''
  end

  # Return the recurrence described in a sentence
  def self.to_words(appointment, options={})
    return "" if appointment.recur_rule.blank?
    appointment.recur_rule =~ /FREQ=([A-Z]*);BYDAY=([A-Z,]*)/
    freq = FREQ[$1] unless $1.blank?
    days = $2.split(',').map{|d| DAYS_OF_WEEK[d]} unless $2.blank?
    if freq.blank? || days.blank? || days.empty?
      ""
    else
      "Recurs #{freq} on #{days.to_sentence} starting at #{appointment.start_at.in_time_zone.to_s(:appt_time)} and running for #{Duration.to_words(appointment.duration)}"
    end
  end
  
end