class CreateLogEntries < ActiveRecord::Migration
  def self.up
    create_table :peanut_log_entries do |t|
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
    drop_table :peanut_log_entries
  end
end
