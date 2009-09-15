class LogEntry < ActiveRecord::Base
  belongs_to              :loggable, :polymorphic => true
  belongs_to              :company
  belongs_to              :user
  belongs_to              :customer, :class_name => 'User'
  
  # LogEntries must be associated with a company. We usually capture the user who created the event, but not necessarily.
  validates_presence_of   :etype, :company_id

  # LogEntry types
  URGENT                  = 1               # urgent messages
  APPROVAL                = 2               # messages indicating that approval is required
  INFORMATIONAL           = 3               # informational messages

  named_scope             :urgent, :conditions => {:etype => URGENT}
  named_scope             :approval, :conditions => {:etype => APPROVAL}
  named_scope             :informational, :conditions => {:etype => INFORMATIONAL}
  named_scope             :seen, :conditions => {:state => "seen"}
  named_scope             :unseen, :conditions => {:state => "unseen"}
  
  # order by start_at, most recent first
  named_scope             :order_recent, {:order => 'updated_at DESC'}
  
  # Will paginate paging info
  def self.per_page
     10
  end
  
  # BEGIN acts_as_state_machine
  include AASM
  
  aasm_column           :state

  aasm_initial_state    :unseen
  aasm_state            :unseen
  aasm_state            :seen
  
  aasm_event :mark_as_seen do
    transitions :to => :seen, :from => [:unseen, :seen]
  end

  aasm_event :mark_as_unseen do
    transitions :to => :unseen, :from => [:unseen, :seen]
  end
  # END acts_as_state_machine

  def seen?
    self.state == "seen"
  end
    
  def make_event()
  end

  def etype_to_s
    case self.etype
    when URGENT
      "urgent"
    when APPROVAL 
      "approval"
    when INFORMATIONAL
      "informational"
    else 
      ""
    end
  end

end
