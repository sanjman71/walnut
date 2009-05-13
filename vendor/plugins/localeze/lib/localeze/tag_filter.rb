module Localeze
  
  class TagFilter

    # @@attr_group_names_to_tags_list = ["Chains & Franchises", "Meals Served"]
    # the attributes for these group names are used as tags
    @@valid_group_names_for_tags  = ["Accessories", "Clothing", "Dance Styles", 
                                     "Facilities", "Facility Features", "Fine Art", "Financial Services", "Finished Products", "Footwear Repair",
                                     "General Tax Services", "Hair Services", "Insurance", 
                                     "Menu Items", "Menus", "Moving Vehicles", 
                                     "Painting Services", "Pest Types", "Pet Care Services", "Products", "Products & Supplies",
                                     "Qualifications & Certifications", "Restaurant Style",
                                     "Salon & Spa Services", "Spa Services", "Services", "Team Sports", "Technology",
                                     "Vehicle Type", "Vehicles", "Veterinary Care", "Veterinary Specialities", "Venues", "Wireless Providers"
                                    ]

    # the attributes for these brands are used as tags
    @@valid_brand_categories      = ["Apparel", "Apperal & Accessories", "Appliances", "Audio & Electronics", 
                                     "Batteries", "Beauty Products", "Bedding", 
                                     "Cables & Wires", "Cameras", "Cell Phones", "Coffee", "Computers", "Cosmetics", "Credit Cards", "Crock Pots",
                                     "Data Storage", "Electronics", "Engine Parts", "Equipment", "Eyewear", 
                                     "Fax Machines", "Fixtures", "Flooring", "Furniture", 
                                     "Gaming Systems", "Hair Care", "Hair Products", "Hardware", "Heaters", "Home Theater Systems",
                                     "Jewelry", "Lighting", "Mail Services", "Mattresses", "Memory Cards", "Nail Care", 
                                     "Oil & Lube", "Ovens & Stoves",
                                     "Paint", "Plumbing Supplies", "Roofing",
                                     "Salon Equipment", "Shirts", "Sinus Medication", "Shoes", "Skin Care & Cosmetics", "Soft Drinks", "Software",
                                     "Telecommunications", "Tires", "Tires & Wheels", "Toner", "Tools", "Toys",
                                     "Vacuums", "Vehicles", "Video Games", "Video Games & Systems",
                                     "Watches", "Water Heaters", "Wireless Provider Services",
                                     "Yard Equipment"
                                    ]
    
    def self.to_tags(group_name, attr_name)
      tags = []
      
      if @@valid_group_names_for_tags.include?(group_name)
        # use attribute name as the tag
        tags += TagGroup::validate_and_clean_string(attr_name)
      elsif brand?(group_name) and @@valid_brand_categories.include?(category = brand_category(group_name))
        # use brand category and attribute as tags
        tags += TagGroup::validate_and_clean_string(category)
        tags += TagGroup::validate_and_clean_string(attr_name)
      elsif cuisine?(group_name)
        # use attribute name to build the tag - e.g. "Chinese" + "food"
        # note: strip 'food' from attr_name if it already exists
        tags += TagGroup::validate_and_clean_string("#{attr_name.gsub(/food/i, '').strip} food")
      end
      
      tags
    end
    
    def self.brand?(group_name)
      group_name.match(/^Brands -/)
    end
    
    def self.brand_category(group_name)
      m = group_name.match(/^Brands - ([\s\w&,]*)/)
      m[1]
    end

    def self.cuisine?(group_name)
      group_name.match(/^Cuisine$/)
    end
    
  end
  
end