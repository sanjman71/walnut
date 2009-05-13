namespace :tags do
  
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
