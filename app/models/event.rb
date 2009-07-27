class Event < ActiveRecord::Base
  belongs_to :location
  
  acts_as_taggable_on       :event_tags

  def after_remove_tagging(tag)
    Event.decrement_counter(:taggings_count, id)
    Tag.decrement_counter(:taggings_count, tag.id)
  end
end