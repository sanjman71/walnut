class CreateCapacitySlot2s < ActiveRecord::Migration
  def self.up
    drop_table    :capacity_slots
    
    create_table  :capacity_slots do |t|
      t.references    :company
      t.references    :provider, :polymorphic => true
      t.references    :location
      t.datetime      :start_at
      t.datetime      :end_at
      t.integer       :duration
      t.integer       :capacity
    end
    
    Company.all.each do |company|
      puts "Processing company #{company.name}"
      # Fix all 0 capacity work appointments - these were forced previously
      company.appointments.work.each do |work_appointment|
        if work_appointment.capacity == 0
          work_appointment.capacity = work_appointment.service.capacity
          work_appointment.save
        end
      end
      
      # Add capacity for each free appointment
      company.appointments.free.each do |appointment|
        CapacitySlot2.change_capacity(company, appointment.location || Location.anywhere, appointment.provider, 
                                      appointment.start_at, appointment.end_at, appointment.capacity, :force => true)
      end

      # Remove capacity for each work appointment that hasn't been cancelled
      company.appointments.work.not_canceled.each do |appointment|
        CapacitySlot2.change_capacity(company, appointment.location || Location.anywhere, appointment.provider, 
                                      appointment.start_at, appointment.end_at, -appointment.capacity, :force => true)
      end
    end
    
  end

  def self.down
    drop_table  :capacity_slot2s

    create_table "capacity_slots" do |t|
      t.integer  "free_appointment_id"
      t.datetime "start_at"
      t.datetime "end_at"
      t.integer  "duration"
      t.integer  "capacity"
      t.integer  "time_start_at"
      t.integer  "time_end_at"
      t.datetime "created_at"
      t.datetime "updated_at"
    end

  end
end
