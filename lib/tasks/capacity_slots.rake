namespace :calendar do
  
  namespace :capacity_slots do

    desc "rebuild capacity slots for all companies"
    task :rebuild_all do
        
      Company.with_appointments.each do |company|
        rebuild_capacity_slots_for_company(company)
      end

    end

    desc "rebuild capacity slots for a company. Specify company subdomain in SUBDOMAIN environment variable"
    task :rebuild_company do

      company = nil
      subdomain = ENV["SUBDOMAIN"]
      company = Company.find_by_subdomain(subdomain.downcase) unless subdomain.blank?
      
      if subdomain.blank?
        puts "You must specify the company subdomain in the SUBDOMAIN environment variable" and return 
      elsif company.blank?
        puts "You provided an invalid subdomain"
      else
        rebuild_capacity_slots_for_company(company)
      end

    end

  end

  def rebuild_capacity_slots_for_company(company)

    puts "Processing company #{company.name}"

    # Fix all 0 capacity work appointments - these were forced previously
    # We do this in a transaction
    Appointment.transaction do

      company.appointments.work.each do |work_appointment|
        if work_appointment.capacity == 0
          work_appointment.capacity = work_appointment.service.capacity
          work_appointment.save
        end
      end
      
    end

    # Process the capacity slots for a company in a transaction
    CapacitySlot.transaction do

      # Remove all existing capacity slots for the company
      company.capacity_slots.destroy_all

      # Add capacity for each free appointment
      company.appointments.free.each do |appointment|
        CapacitySlot.change_capacity(company, appointment.location || Location.anywhere, appointment.provider, 
                                      appointment.start_at, appointment.end_at, appointment.capacity, :force => true)
      end

      # Remove capacity for each work appointment that hasn't been cancelled
      company.appointments.work.not_canceled.each do |appointment|
        CapacitySlot.change_capacity(company, appointment.location || Location.anywhere, appointment.provider, 
                                      appointment.start_at, appointment.end_at, -appointment.capacity, :force => true)
      end

    end

  end

end
