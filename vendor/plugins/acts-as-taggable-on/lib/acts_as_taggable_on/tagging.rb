class Tagging < ActiveRecord::Base #:nodoc:
  belongs_to :tag, :counter_cache => :taggings_count
  # SK - added counter cache
  belongs_to :taggable, :polymorphic => true, :counter_cache => :taggings_count
  belongs_to :tagger, :polymorphic => true
  validates_presence_of :context
end