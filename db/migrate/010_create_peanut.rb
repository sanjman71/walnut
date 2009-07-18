class CreatePeanut < ActiveRecord::Migration
  def self.up
    # Rename places and any references to places
    
    rename_table :places, :companies

    change_table :companies do |t|
      t.string  :time_zone, :limit => 100
      t.string  :subdomain, :limit => 100
      t.string  :slogan, :limit => 100
      t.text    :description
      t.integer :services_count, :default => 0        # counter cache
      t.integer :work_services_count, :default => 0   # counter cache
      t.integer :providers_count, :default => 0       # counter cache
    end

    rename_table :location_places, :company_locations

    change_table :company_locations do |t|
      t.rename :place_id, :company_id
    end
    
    rename_table :place_tag_groups, :company_tag_groups

    change_table :company_tag_groups do |t|
      t.rename :place_id, :company_id
    end

    change_table :chains do |t|
      t.rename :places_count, :companies_count
    end

    change_table :tag_groups do |t|
      t.rename  :places_count, :companies_count
    end
    
    change_table :locations do |t|
      t.integer :appointments_count, :default => 0
    end
    
    create_table :services do |t|
      t.string  :name
      t.integer :duration
      t.string  :mark_as
      t.integer :price_in_cents
      t.integer :providers_count, :default => 0             # counter cache
      t.boolean :allow_custom_duration, :default => false   # by default no custom duration

      t.timestamps
    end

    add_index :services, [:mark_as]

    # map services to companies
    create_table :company_services do |t|
      t.integer :company_id
      t.integer :service_id
    end

    add_index :company_services, [:company_id]
    add_index :company_services, [:service_id]
    
    create_table :products do |t|
      t.integer   :company_id
      t.string    :name
      t.integer   :inventory
      t.integer   :price_in_cents
      t.timestamps
    end
  
    add_index :products, [:company_id]
    add_index :products, [:company_id, :name]

    # Map polymorphic providers (e.g. users) to companies
    create_table :company_providers do |t|
      t.references  :company
      t.references  :provider, :polymorphic => true
      t.timestamps
    end
    
    add_index :company_providers, [:provider_id, :provider_type], :name => 'index_on_providers'
    add_index :company_providers, [:company_id, :provider_id, :provider_type], :name => 'index_on_companies_and_providers'

    # Polymorphic relationship mapping services to provider (e.g. users, things)
    create_table :service_providers do |t|
      t.references  :service
      t.references  :provider, :polymorphic => true
      t.timestamps
    end

    add_index :service_providers, [:service_id, :provider_id, :provider_type], :name => 'index_on_services_and_providers'
    
    create_table :resources do |t|
      t.string  :name
      t.string  :description
    end
    
    add_index :resources, [:name]
    
    create_table :appointments do |t|
      t.references  :company
      t.references  :service
      t.references  :location
      t.references  :provider,            :polymorphic => true    # e.g. users
      t.references  :customer      # user who booked the appointment
      t.string      :when
      t.datetime    :start_at
      t.datetime    :end_at
      t.integer     :duration
      t.string      :time
      t.integer     :time_start_at    # time of day
      t.integer     :time_end_at      # time of day
      t.string      :mark_as
      t.string      :state
      t.string      :confirmation_code
      t.string      :uid              # The iCalendar UID
      t.text        :description
      t.datetime    :canceled_at
      t.boolean     :public,              :default => false

      t.string      :name,                :limit => 100
      t.integer     :popularity,          :default => 0
      t.string      :url,                 :limit => 200
      t.integer     :taggings_count,      :default => 0   # counter cache
      t.string      :source_type,         :limit => 20
      t.string      :source_id,           :limit => 50

      # Recurrence information
      t.references  :recur_parent, :class => "Appointment"  # If this appointment is an instance of a recurring appointment
      t.string      :recur_rule, :limit => 200              # iCalendar recurrence rule
      t.datetime    :recur_expanded_to                      # recurrence has been expanded up to this datetime (in UTC)
      t.integer     :recur_remaining_count                  # The count can be added to the recur_rule. Not currently supported / used
      t.datetime    :recur_until                            # The recurrence ends before this datetime
      t.integer     :recur_instances_count                  # The number of recurrence instances

      t.timestamps
    end

    add_index :appointments, [:company_id, :start_at, :end_at, :duration, :time_start_at, :time_end_at, :mark_as], :name => "index_on_openings"
    add_index :appointments, :location_id
    add_index :appointments, :popularity
    add_index :appointments, :taggings_count
    
    create_table :appointment_event_categories, :force => :true do |t|
      t.references  :appointment
      t.references  :event_category
      t.timestamps
    end
    
    create_table :invoice_line_items do |t|
      t.integer     :invoice_id
      t.references  :chargeable, :polymorphic => true
      t.integer     :price_in_cents
      t.integer     :tax
      t.timestamps
    end
    
    create_table :invoices do |t|
      t.references  :invoiceable, :polymorphic => true
      t.integer     :gratuity_in_cents
      t.timestamps
    end
    
    create_table :notes do |t|
      t.text  :comment
      t.timestamps
    end
    
    # Polymorphic relationship mapping notes to different subjects (e.g. people, appointments)
    create_table :notes_subjects do |t|
      t.references  :note
      t.references  :subject, :polymorphic => true
    end
    
    create_table :invitations do |t|
      t.integer   :sender_id
      t.integer   :recipient_id
      t.string    :recipient_email
      t.string    :token
      t.string    :role
      t.datetime  :sent_at
      t.integer   :company_id
      
      t.timestamps
    end
    
    add_index :invitations, :token

    create_table :plans do |t|
      t.string      :name
      t.boolean     :enabled
      t.string      :icon
      t.integer     :cost   # value in cents
      t.string      :cost_currency
      t.integer     :max_locations
      t.integer     :max_providers
      t.integer     :start_billing_in_time_amount   # e.g. 1, 5, 30
      t.string      :start_billing_in_time_unit     # e.g. days, months
      t.integer     :between_billing_time_amount    # e.g. 1, 5, 30
      t.string      :between_billing_time_unit      # e.g. days, months

      t.timestamps
    end

    create_table :payments do |t|
      t.references  :subscription
      t.string      :description 
      t.integer     :amount
      t.string      :state, :default => 'pending'
      t.boolean     :success 
      t.string      :reference 
      t.string      :message 
      t.string      :action 
      t.text        :params 
      t.boolean     :test
      t.timestamps
    end  
    
    create_table :subscriptions do |t|
      t.references  :user
      t.references  :company
      t.references  :plan
      t.datetime    :start_billing_at
      t.datetime    :last_billing_at
      t.datetime    :next_billing_at
      t.integer     :paid_count, :default => 0
      t.integer     :billing_errors_count, :default => 0
      t.string      :vault_id, :default => nil
      t.string      :state, :default => 'initialized'
      t.timestamps
    end

    create_table :log_entries do |t|
      t.references  :loggable, :polymorphic => true  # e.g. appointment
      t.references  :company, :null => false            # company this is relevant to
      t.references  :location                           # company location this is relevant to, if any
      t.references  :customer                           # customer this is relevant to, if any
      t.references  :user                               # user who created the log_entry
      t.text        :message_body                       # message body
      t.integer     :message_id                         # one of the standard message IDs
      t.integer     :etype                              # informational, approval, urgent
      t.string      :state
      t.timestamps
    end

  end

  def self.down
    remove_column :companies, :time_zone
    remove_column :companies, :subdomain
    remove_column :companies, :slogan
    remove_column :companies, :description
    remove_column :companies, :services_count
    remove_column :companies, :work_services_count
    remove_column :companies, :providers_count
    
    rename_table  :companies, :places

    change_table :company_locations do |t|
      t.rename :company_id, :place_id
    end
    
    rename_table  :company_locations, :location_places
    
    change_table :company_tag_groups do |t|
      t.rename :company_id, :place_id
    end

    rename_table :company_tag_groups, :place_tag_groups

    change_table :chains do |t|
      t.rename :companies_count, :places_count
    end

    change_table :tag_groups do |t|
      t.rename  :companies_count, :places_count
    end

    remove_column :locations, :appointments_count
    
    drop_table  :log_entries
    drop_table  :subscriptions
    drop_table  :payments
    drop_table  :plans
    drop_table  :invitations
    drop_table  :notes_subjects
    drop_table  :notes
    drop_table  :invoices
    drop_table  :invoice_line_items
    drop_table  :appointments
    drop_table  :resources
    drop_table  :service_providers
    drop_table  :company_providers
    drop_table  :products
    drop_table  :company_services
    drop_table  :services
  end
end
