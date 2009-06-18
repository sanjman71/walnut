namespace :tags do
  
  desc "Mark untagged places based on rules in yaml file"
  task :mark_untagged_places do
    s = YAML::load_stream( File.open("data/untagged_places.yml"))

    checked = 0
    tagged  = 0
    
    s.documents.each do |object|
      regex       = object["regex"]
      tag_groups  = Array(object["tag_groups"])

      tag_groups  = tag_groups.collect do |s|
        tag_group = TagGroup.find_by_name(s)
      end.compact
      
      puts "#{Time.now}: *** using regex: #{regex}, tag groups: #{tag_groups.collect(&:name).join(",")}"

      conditions = ["taggings_count = 0 AND name REGEXP '[[:<:]]%s[[:>:]]'", regex]

      if tag_groups.any?
        c, t    = add_place_tag_groups(conditions, tag_groups, [])
        checked += c
        tagged  += t
      end
    end
    
    puts "#{Time.now}: completed, checked #{checked} places, tagged #{tagged} places"
  end
  
  desc "Find places without any tags"
  task :find_untagged_places do
    filter  = ENV["FILTER"] ? ENV["FILTER"] : nil
    
    puts "#{Time.now}: finding untagged places, filter: #{filter}"
    
    # find places with no taggings and filter enclosed within a word boundary 
    conditions = ["taggings_count = 0 AND name REGEXP '[[:<:]]%s[[:>:]]'", filter]
    checked, tagged = add_place_tag_groups(conditions, [], [])

    puts "#{Time.now}: completed, checked #{checked} places, tagged #{tagged} places"
  end
  
  def add_place_tag_groups(conditions, tag_groups, tags)
    checked = 0
    tagged  = 0
    
    Place.find_in_batches(:batch_size => 100, :conditions => conditions) do |places|
      places.each do |place|
        puts "#{Time.now}: #{place.name}:#{place.primary_location.city.name}:#{place.primary_location.street_address}"
        
        checked += 1

        if tag_groups.any?
          # add place to each tag group
          tag_groups.each do |tag_group|
            tag_group.places.push(place)
            tagged += 1
          end
        end
        
        if tags.any?
          # add place tags
          place.tag_list.add(tags)
          place.save
          tagged += 1
        end
      end
    end
    
    [checked, tagged]
  end
  
  desc "Find tags >= WORDS words in length"
  task :find_min_words do
    words = ENV["WORDS"].to_i
    
    if words == 0
      puts "missing WORDS"
      exit
    end
    
    tags = Tag.all.select { |t| t.name.split.size >= words }
    
    puts "#{Time.now}: found #{tags.size} tags that are at least #{words} words in length"
    
    tags.each do |tag|
      puts "*** #{tag.name}:#{tag.taggings_count}"
    end
    
    puts "#{Time.now}: completed"
  end
  
  desc "Find tags matching FILTER"
  task :find do
    filter = ENV["FILTER"] ? ENV["FILTER"] : nil
    
    if filter.blank?
      puts "missing FILTER"
      exit
    end
    
    tags = Tag.all(:conditions => ["name REGEXP '%s'", filter])

    puts "#{Time.now}: found #{tags.size} tags matching #{filter}"
    
    tags.each do |tag|
      puts "*** #{tag.name}:#{tag.taggings_count}"
    end
    
    puts "#{Time.now}: completed"
  end
  
  desc "Merge tag TAG_FROM to TAG_TO"
  task :merge do
    tag_from  = Tag.find_by_name(ENV["TAG_FROM"])
    tag_to    = Tag.find_by_name(ENV["TAG_TO"])
    
    if tag_from.blank? or tag_to.blank?
      puts "missing TAG_FROM or TAG_TO"
      exit
    end
    
    merge_tags(tag_from, tag_to)
    
    puts "#{Time.now}: completed"
  end
  
  desc "Merge the default set of tags"
  task :merge_default do
    merge_hash = Hash["beauty salons" => "beauty salon",
                      "groceries" => "grocery",
                      "hair salons" => "hair salon",
                      "nail salons" => "nail salon",
                      "salons" => "salon"]
                      
    merge_hash.each_pair do |key, value|
      tag_from = Tag.find_by_name(key)
      tag_to   = Tag.find_by_name(value)
      
      next if tag_from.blank? or tag_to.blank?
      
      merge_tags(tag_from, tag_to)
    end
    
    puts "#{Time.now}: completed"
  end
  
  def merge_tags(tag_from, tag_to)
    puts "#{Time.now}: merging #{tag_from.name}:#{tag_from.taggings.count} to #{tag_to.name}:#{tag_to.taggings.count}"

    # merge tags and reload
    TagHelper.merge_tags(tag_from, tag_to)
    tag_to.reload
    
    puts "#{Time.now}: completed, merged tag #{tag_to.name}:#{tag_to.taggings.count}"
  end
  
  desc "Remove tag TAG"
  task :remove do
    tag = Tag.find_by_name(ENV["TAG"])
    
    if tag.blank?
      puts "missing TAG"
      exit
    end
    
    puts "#{Time.now}: removing #{tag.name}:#{tag.taggings.count}"
    
    TagHelper.remove_tag(tag)
    
    puts "#{Time.now}: completed, removed tag #{tag.name}"
  end
  
  desc "Cleanup tags"
  task :cleanup do
    unused  = 0
    used    = 0
    fixed   = 0
    
    Tag.all.each do |tag|
      # 'count' doesn't use the counter cache value
      count = tag.taggings.count
      
      if count > 0 
        if count != tag.taggings_count
          # fix count, but taggings_count is a readonly counter cache field
          # tag.update_attribute(:taggings_count, count)
          fixed += 1
        end
        
        used += 1
        next
      end

      # tag is not being used
      tag.destroy
      puts "*** removed tag: #{tag.name}"
      unused += 1
    end
    
    puts "#{Time.now}: completed, found #{used} tags, fixed #{fixed} tags, removed #{unused} tags"
  end
  
end
