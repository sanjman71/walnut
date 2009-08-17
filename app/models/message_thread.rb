class MessageThread < ActiveRecord::Base
  belongs_to                :message
  validates_presence_of     :message_id, :thread
  validates_uniqueness_of   :message_id, :scope => :thread
  
  before_validation_on_create :make_thread
  
  named_scope :with_thread,   lambda { |o| {:conditions => {:thread => o}} }
  
  protected
  
  def make_thread
    if self.thread.blank?
      self.thread = Time.now.strftime("%Y%m%d%H%M%S")
    end
  end
end