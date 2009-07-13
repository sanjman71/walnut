class Note < ActiveRecord::Base
  validates_presence_of     :comment
  has_many_polymorphs       :subjects, :from => [:appointments, :users]
  attr_accessor             :subject

  named_scope               :sort_recent, {:order => "created_at DESC"}
  
  def after_initialize
    # after_initialize can also be called when retrieving objects from the database
    return unless new_record?
    
    if @subject_type and @subject_id
      begin
        @subject = Kernel.const_get(@subject_type).find_by_id(@subject_id)
      end
    end
  end
  
  def after_create
    if @subject
      # add note subject
      self.subjects.push(@subject)
    end
  end
  
  
  # BEGIN virtual attributes
  def subject_id=(id)
    @subject_id = id
  end
  
  def subject_type=(type)
    @subject_type = type
  end
  # END virtual attributes
end