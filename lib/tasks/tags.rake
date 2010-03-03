namespace :tags do

  desc "Mark untagged companies with the specified name filter"
  task :mark_chains_with_tag_groups do
    yaml  = ENV["YAML"]
    path  = "data/#{yaml}"

    if yaml.blank?
      puts "missing YAML arg"
      exit
    end

    if !File.exists?(path)
      puts "missing file #{path}"
      exit
    end

    stream = YAML::load_stream(File.open(path))

    checked = 0
    tagged  = 0

    stream.documents.each do |object|
      chain = Chain.find_by_name(object["chain"]) || Chain.find_by_display_name(object["chain"])

      if chain.blank?
        puts "[error] could not find chain: #{object['chain']}"
        next
      end

      # find the tag groups
      set_tag_groups = (object["tag_groups"] || []).collect do |tg|
        TagGroup.find_by_name(tg)
      end.compact

      add_tag_groups = (object['add_tag_groups'] || []).collect do |tg|
        TagGroup.find_by_name(tg)
      end.compact

      remove_tag_groups = (object['remove_tag_groups'] || []).collect do |tg|
        TagGroup.find_by_name(tg)
      end.compact

      puts "*** chain #{chain.display_name} - setting #{set_tag_groups.size} tag groups" unless set_tag_groups.empty?
      puts "*** chain #{chain.display_name} - adding #{add_tag_groups.size} tag groups" unless add_tag_groups.empty?
      puts "*** chain #{chain.display_name} - removing #{remove_tag_groups.size} tag groups" unless remove_tag_groups.empty?

      chain.companies.each do |company|
        if !add_tag_groups.empty?
          # build plus groups by checking against company's existing tag groups
          plus_tag_groups = add_tag_groups.collect{ |o| company.tag_groups.include?(o) ? nil : o }.compact
        elsif set_tag_groups.empty?
          # nothing add
          plus_tag_groups = []
        else
          # build plus groups using set substraction
          plus_tag_groups = set_tag_groups - company.tag_groups
        end

        if !remove_tag_groups.empty?
          # build delete groups by checking against company's existing tag groups
          del_tag_groups = remove_tag_groups.collect{ |o| company.tag_groups.include?(o) ? o : nil }.compact
        elsif set_tag_groups.empty?
          # nothing remove
          del_tag_groups = []
        else
          # build delete group using set subtraction
          del_tag_groups = company.tag_groups - set_tag_groups
        end

        # skip if there are no tag groups to add or delete
        next if plus_tag_groups.empty? and del_tag_groups.empty?

        puts "*** company: #{company.inspect}"

        unless plus_tag_groups.empty?
          puts "*** adding: #{plus_tag_groups.collect(&:name).inspect}" 
          plus_tag_groups.each do |tag_group|
            company.tag_groups.push(tag_group)
          end
        end

        unless del_tag_groups.empty?
          puts "*** removing: #{del_tag_groups.collect(&:name).inspect}" 
          del_tag_groups.each do |tag_group|
            company.tag_groups.delete(tag_group)
          end
        end
      end
    end
  end

  # desc "Mark untagged companies with the specified name filter"
  # task :mark_untagged_companies_with_name do
  #   name = ENV["NAME"]
  #   
  #   if name.blank?
  #     puts ""
  #   end
  # 
  #   companies = Company.no_tag_groups.with_name(name)
  #   
  # end

  desc "Find untagged companies with chains"
  task :find_untagged_companies_with_chains do
    companies = Company.no_tag_groups.with_chain.all(:group => 'companies.name').sort_by { |o| o.name }
    
    companies.each do |company|
      chain = company.chain
      hash  = Hash[]

      # build tag group histogram
      chain.companies.each do |o|
        o.tag_groups.each do |tg|
          hash[tg.name] = hash[tg.name].to_i + 1
        end
      end

      puts "**** company: #{company.name}, hash: #{hash.inspect}"
    end

    puts "#{Time.now}: completed, found #{companies.size} companies"
  end

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
      
      puts "#{Time.now}: *** regex: #{regex}, tag groups: #{tag_groups.collect(&:name).join(" | ")}"

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
    conditions = filter ? ["taggings_count = 0 AND name REGEXP '[[:<:]]%s[[:>:]]'", filter] : ["taggings_count = 0"]
    checked, tagged = add_place_tag_groups(conditions, [], [])

    puts "#{Time.now}: completed, checked #{checked} places, tagged #{tagged} places"
  end
  
  def add_place_tag_groups(conditions, tag_groups, tags)
    checked = 0
    tagged  = 0
    
    Company.find_in_batches(:batch_size => 100, :conditions => conditions) do |companies|
      companies.each do |company|
        puts "#{Time.now}: #{company.name}:#{company.primary_location.city.name}:#{company.primary_location.street_address}"
        
        checked += 1

        if tag_groups.any?
          # add place to each tag group
          tag_groups.each do |tag_group|
            if !tag_group.places.include?(place)
              tag_group.places.push(place)
              tagged += 1
            end
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
                      "pharmacies" => "pharmacy",
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
  
  # Find tags with count == 0, and fix tags with incorrect taggings_count values
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
