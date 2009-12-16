class MessageTopic < ActiveRecord::Base
  belongs_to              :message
  belongs_to              :topic, :polymorphic => true
  validates_presence_of   :message_id, :topic_id, :topic_type
  validates_uniqueness_of :message_id, :scope => [:topic_id, :topic_type]

  named_scope :for_type,  lambda { |o| { :conditions => {:topic_type => o.to_s} }}
end