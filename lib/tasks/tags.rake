namespace :tags do
  
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
