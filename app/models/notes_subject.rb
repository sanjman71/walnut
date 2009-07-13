class NotesSubject < ActiveRecord::Base
  belongs_to                :note
  belongs_to                :subject, :polymorphic => true
  validates_presence_of     :note_id, :subject_id, :subject_type
end