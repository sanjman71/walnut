class StreetAddress
  
  # A street address has the following components:
  #  - :housenumber, :predirectional, :streetname, :streettype, :postdirectional, :apttype, :aptnumber
  #
  #  - examples:
  #  - 200 W Grand Ave
  #  - 6920 N Mannheim Rd
  #  - 175 N State St
  #  - 200 N State St Ste 11
  #
  #  - examples with normalization
  #  - 200 West Grand Ave. => 200 W Grand Ave
  
  # normalize a street address, e.g:
  #  - 200 West Grand Avenue => 200 W Grand Ave
  def self.normalize(s)
    s = s.to_s.downcase
    normalizations = [[".", ""], [",", ""], ["street", "st"], ["avenue", "ave"], ["drive", "dr"], ["#", "ste"], ["boulevard", "blvd"], 
                      ["court", "ct"], ["plaza", "plz"], 
                      ["north", "n"], ["south", "s"], ["east", "e"], ["west", "w"]
                     ]
    normalizations.each do |tuple|
      s.send("gsub!", tuple[0], tuple[1])
    end
    s.split.collect { |token| ["and"].include?(token) ? token : token.capitalize  }.join(" ")
  end
  
  # break a street address into its components, and return the components hash
  def self.components(s)
    index = 0
    hash  = {}
    
    return hash if s.blank?

    # normalize street address and split
    tuple = normalize(s).split(" ")
    token = tuple[index]
    
    # check housenumber
    if housenumber?(token)
      hash[:housenumber] = token
      index += 1
    end

    token = tuple[index]

    # check predirectional
    if predirectional?(token)
      hash[:predirectional] = token.upcase
      index += 1
    end
    
    # streetname is always next
    token = tuple[index]
    hash[:streetname] = token
    index += 1
    stack = []
    
    # we assume its a streetname until we find something else
    while (token = tuple[index])
      if streettype?(token)
        stack = [:aptnumber, :apttype, :postdirectional, :streettype]
        break
      elsif postdirectional?(token)
        stack = [:aptnumber, :apttype, :postdirectional]
        break
      elsif  apttype?(token)
        stack = [:aptnumber, :apttype]
        break
      else 
        # its still the streetname
        hash[:streetname] += " #{token}"
        index += 1
      end
    end
    
    token = tuple[index]
    type  = stack.pop
    
    while (type and token)
      case type
      when :streettype 
        if streettype?(token)
          hash[:streettype] = streettype(token)
          index += 1
        end
      when :postdirectional
        if postdirectional?(token)
          hash[:postdirectional] = token
          index += 1
        end
      when :apttype
        if apttype?(token)
          hash[:apttype] = token
          index += 1
        end
      when :aptnumber
        if aptnumber?(token)
          hash[:aptnumber] = token
          index += 1
        end
      else
        break
      end
      
      # get tuple and pop stack element
      token = tuple[index]
      type  = stack.pop
    end
    
    hash
  end
  
  # return true if the string is a house number
  # "300", "1/2"
  def self.housenumber?(s)
    return true if s =~ /^[\d\/]+$/
    false
  end
  
  # returns true if the string is a valid street type  
  def self.streettype?(s)
    streettype_collection = ["ave", "avenue", "blvd", "boulevard", "ct", "court", "ctr", "dr", "drive", "pl", "rd", "st", "street"]
    streettype_collection.include?(s.to_s.downcase)    
  end
  
  # format the street type
  def self.streettype(s)
    s = s.downcase
    case s
    when 'avenue'
      s = 'ave'
    when 'street'
      s = 'st'
    when 'boulevard'
      s = 'blvd'
    when 'road'
      s = 'rd'
    when 'court'
      s= 'ct'
    end
    
    s.capitalize
  end
  
  # returns true if the string is a valid predirectional
  def self.predirectional?(s)
    return true if s =~ /^\w$/
    return false
  end

  # returns true if the string is a valid postdirectional
  def self.postdirectional?(s)
    return predirectional?(s)
  end
  
  # returns true if the string is a valid apt type
  def self.apttype?(s)
    collection = ["#", "apt", "fl", "floor", "lbby", "lobby", "ofc", "office", "ste", "suite", "unit"]
    collection.include?(s.to_s.downcase)
  end
  
  # any non-empty string is a valid apt number
  def self.aptnumber?(s)
    return true if !s.blank?
  end
end