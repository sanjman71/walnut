module GeoTagCountModule
  
  # set geo tag counts using sphinx facets
  def set_tag_counts(tag_limit=nil)
    tag_limit ||= ::Search.max_matches
    
    # build location tag counts
    facets    = Location.facets(:with => ::Search.attributes(self), :facets => "tag_ids", :limit => tag_limit)
    tags      = ::Search.load_from_facets(facets, Tag)
    
    if self.respond_to?(:events_count) and self.events_count > 0
      # add event tag counts
      facets  = Appointment.facets(:with => ::Search.attributes(self), :facets => "tag_ids", :limit => tag_limit)
      tags   += ::Search.load_from_facets(facets, Tag)
    end

    # sort tags by taggings count
    tags      = tags.uniq.sort_by{ |o| -o.taggings_count }.slice(0, tag_limit)
    
    # build list of tags to add and delete
    cur_tags  = self.tags
    add_tags  = tags - cur_tags
    del_tags  = cur_tags - tags
    added     = 0
    deleted   = 0

    add_tags.each do |tag|
      self.geo_tag_counts.create(:tag => tag, :taggings_count => tag.taggings_count)
      added += 1
    end

    del_tags.each do |tag|
      o = self.geo_tag_counts.find_by_tag_id(tag.id)
      self.geo_tag_counts.delete(o)
      deleted += 1
    end

    [added, deleted]
  end

end