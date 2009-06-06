class TagHelper
  
  # merge tag 'tag_from' to tag 'tag_to'
  def self.merge_tags(tag_from, tag_to)
    tag_from.taggings.each do |tagging|
      taggable = tagging.taggable
      taggable.tag_list.remove(tag_from.name)
      taggable.tag_list.add(tag_to.name)
      taggable.save
    end

    tag_from.reload
    
    # remove 'tag_from' if all tags were removed
    remove_tag(tag_from)
  end
  
  def self.remove_tag(tag)
    tag.taggings.each do |tagging|
      taggable = tagging.taggable
      taggable.tag_list.remove(tag.name)
      taggable.save
    end
    
    tag.reload
    
    # remove 'tag' if all tags were removed
    if tag.taggings.count == 0
      tag.destroy
    end
  end
end