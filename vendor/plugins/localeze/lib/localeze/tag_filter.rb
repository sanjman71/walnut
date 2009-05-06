module Localeze
  
  class TagFilter

    # @@attr_group_names_to_tags_list = ["Chains & Franchises", "Meals Served"]
    # the attributes for these group names are used as tags
    @@valid_group_names_for_tags  = ["Financial Services", "General Tax Services", "Hair Services", "Insurance", 
                                     "Menu Items", "Menus", "Painting Services", "Products", "Spa Services", "Venues", "Wireless Providers"
                                    ]

    # the attributes for these brands are used as tags
    @@valid_brand_categories      = ["Apparel", "Appliances", "Beauty Products", "Cameras", "Cell Phones", "Coffee", "Computers", "Credit Cards", 
                                     "Electronics", "Engine Parts", "Equipment", "Eyewear", "Fixtures", "Furniture", 
                                     "Gaming Systems", "Hair Care", "Hair Products", "Hardware", "Heaters", "Home Theater Systems",
                                     "Jewelry", "Lighting", "Mail Services", "Mattresses", "Memory Cards", "Nail Care", 
                                     "Oil & Lube", "Paint", "Plumbing Supplies", "Shoes", "Tires", "Tires & Wheels", "Tools", 
                                     "Vacuums", "Vehicles", "Watches",
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