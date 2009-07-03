class TagHelper
  
  @@tag_group_mappings = Hash["Appraisers" => "Real Estate - Appraisers",
                              "Advertising Agencies" => "Advertising",
                              "Advertising Newspaper" => "Newspapers",
                              "Air Cargo and Package Express Service" => "Cargo and Freight Services",
                              "Aircraft Charter Rental & Leasing" => "Aircraft Charters and Rentals",
                              "Aircraft Dealers" => "Aircraft Dealers and Services",
                              "Aircraft Service & Maintenance" => "Aircraft Dealers and Services",
                              "Alcoholism Information & Treatment Centers" => "Drug and Alcohol Resources",
                              "Ambulance Service" => "Ambulance and Rescue Services",
                              "Animal Shelters" => "Animal Shelters and Humane Societies",
                              "Antique Dealers" => "Antiques",
                              "Appliance Supplies and Parts" => "Appliance Repair and Supplies",
                              "Architects and Builders Service" => "Architects",
                              "Art Galleries Dealers and Consultants" => "Artists and Art Dealers",
                              "Asphalt and Asphalt Products" => "Contractors - Paving",
                              "Assisted Living Facilities" => "Retirement and Assisted Living Facilities",
                              "Attorneys Accident Personal Injury and Property Damage Law" => "Law - Personal Injury and Property Damage",
                              "Attorneys Administrative and Government Law" => "Law - Governmental Issues",
                              "Attorneys Bankruptcy Law" => "Law - Financial and Bankruptcy",
                              "Attorneys Criminal Law" => "Law - Criminal",
                              "Attorneys Driving Dui Dwi Law" => "Law - Driving and Traffic",
                              "Attorneys Employment and Labor Law" => "Law - Labor and Employment",
                              "Attorneys Marriage and Family Law" => "Law - Divorce and Family",
                              "Attorneys Patent Law" => "Law - Patent, Trademark and Copyright",
                              "Attorneys Real Estate Law" => "Law - Real Estate",
                              "Attorneys Trademark and Copyright Law" => "Law - Patent, Trademark and Copyright",
                              "Attorneys Wills Trusts and Estate Planning Law" => "Law - Wills and Estate Planning",
                              "Audio Visual Equipment Dealers" => "Electronics - Audio Visual",
                              "Automobile Accessories and Trim" => "Automobile - Parts and Accessories",
                              "Automobile Body Repairs and Painting" => "Automobile - Body Repairs and Painting",
                              "Automobile Body Shop Equipment and Supplies" => "Automobile - Body Repairs and Painting",
                              "Automobile Body Shop Services" => "Automobile - Body Repairs and Painting",
                              "Automobile Dealers New and Used" => "Automobile - Dealers",
                              "Automobile Dealers Used Cars and Vans" => "Automobile - Dealers",
                              "Automobile Dealers" => "Automobile - Dealers",
                              "Automobile License and Title Services" => "Automobile - License and Title Services",
                              "Automobile Parts and Accessories" => "Automobile - Parts and Accessories",
                              "Automobile Parts and Supplies" => "Automobile - Parts and Accessories",
                              "Automobile Rentals" => "Automobile - Rentals",
                              "Automobile Renting and Leasing" => "Automobile - Rentals",
                              "Automobile Repair and Service Equipment & Supplies" => "Automobile - Repairs and Services",
                              "Automobile Repairs and Services" => "Automobile - Repairs and Services",
                              "Automobile Repair and Service Equipment and Supplies" => "Automobile - Repairs and Services",
                              "Automobile Tires" => "Automobile - Tires",
                              "Automobile Towing" => "Automobile - Towing",
                              "Automobile Wash and Detailing" => "Automobile - Wash and Detailing",
                              "Banks" => "Banks and Credit Unions",
                              "Banks and Credit Unions" => "Banks and Credit Unions",
                              "Banks Commercial" => "Banks and Credit Unions",
                              "Bars Grills and Pubs" => "Bars, Grills and Pubs",
                              "Beauty Salons" => "Beauty Salons and Day Spas",
                              "Beauty Supplies and Equipment" => "Hair and Beauty Supplies, Service and Equipment",
                              # "BEER & ALE WHOLESALE"
                              "Child Care Services" => "Child Care Centers and Services",
                              "Clothing" => "Clothing and Accessories",
                              "Consultants Business" => "Consultants - Business",
                              "Consultants Environment" => "Consultants - Environment",
                              "Contractors Building" => "Contractors - Building",
                              "Contractors Carpentry" => "Contractors - Carpentry",
                              "Contractors Computer" => "Contractors - Computer",
                              "Contractors Concrete" => "Contractors - Concrete",
                              "Contractors Drywall" => "Contractors - Drywall",
                              "Contractors Electric" => "Contractors - Electrical",
                              "Contractors Electrical" => "Contractors - Electrical",
                              "Contractors Excavation and Wrecking" => "Contractors - Excavation and Wrecking",
                              "Contractors Insulation" => "Contractors - Insulation",
                              "Contractors Masonry" => "Contractors - Masonry",
                              "Contractors Painting" => "Contractors - Painting",
                              "Contractors Paving" => "Contractors - Paving",
                              "Contractors Plumbers and Plumbing" => "Contractors - Plumbers and Plumbing",
                              "Contractors Roofing" => "Contractors - Roofing",
                              "Contractors Sewer" => "Contractors - Sewer",
                              "Contractors Siding" => "Contractors - Siding",
                              "Contractors Tile, Marble and Granite" => "Contractors - Tile, Marble and Granite",
                              "Convenience Stores" => "Convenience Stores and Service Stations",
                              # "Credit Unions" => "",
                              "Electronics Audio Visual" => "Electronics - Audio Visual",
                              "Electronics Computers" => "Electronics - Computers",
                              "Electronics Dealers" => "Electronics - Dealers",
                              "Electronics Equipment and Services" => "Electronics - Equipment and Services",
                              "Electronics Home Entertainment" => "Electronics - Home Entertainment",
                              "Electronics Printers" => "Electronics - Printers",
                              "Electronics Telephone" => "Electronics - Telephone",
                              "Hardware" => "Hardware Tools and Services",
                              "Liquor Stores Retail" => "Liquor Stores",
                              "Loans" => "Loans and Mortgages",
                              "Modeling" => "Modeling",
                              "Modeling Agencies" => "Modeling Agencies",
                              "Mortgages" => "Loans and Mortgages",
                              # "Museums" => "",
                              "Optometrists Od" => "Physicians - Optometry and Opthalmology",
                              "Physicians and Surgeons" => "Physicians - General",
                              "Physicians and Surgeons Allergy Asthma and Immunology" => "Physicians - Allergy Asthma and Immunology",
                              "Physicians and Surgeons Anesthesiology" => "Physicians - Anesthesiology",
                              "Physicians and Surgeons Cardiology" => "Physicians - Cardiology",
                              "Physicians and Surgeons Dpm Podiatrists" => "Physicians - Podiatry",
                              "Physicians and Surgeons Family and General Practice" => "Physicians - Family and General Practice",
                              "Physicians and Surgeons Internal Medicine" => "Physicians - Internal Medicine",
                              "Physicians and Surgeons Neurology" => "Physicians - Neurology and Neurosurgery",
                              "Physicians and Surgeons Obstetrics and Gynecology" => "Physicians - Obstetrics and Gynecology",
                              "Physicians and Surgeons Opthalmology" => "Physicians - Optometry and Opthalmology",
                              "Physicians and Surgeons Pediatrics" => "Physicians - Pediatrics",
                              "Physicians and Surgeons Psychiatry" => "Physicians - Psychiatry",
                              "Physicians and Surgeons Radiology" => "Physicians - Radiology",
                              "Physicians and Surgeons Surgery General" => "Physicians - General",
                              "Physicians and Surgeons Surgery Hand" => "Physicians - Hand",
                              "Physicians Naturopathic Nmd" => "Physicians - Alternative",
                              "Railroad Construction" => "Railroads",
                              # "REAL ESTATE" => "",
                              "Real Estate Apartments and Condominiums" => "Real Estate - Apartments and Condominiums",
                              "Real Estate Appraisers" => "Real Estate - Appraisers",
                              "Real Estate Brokers and Agents" => "Real Estate - Brokers and Agents",
                              "Real Estate Commercial and Industrial" => "Real Estate - Commercial and Industrial",
                              # "Real Estate Developers" => "Real Estate - Development",
                              "Real Estate Development" => "Real Estate - Development",
                              "Real Estate Investments" => "Real Estate - Investments",
                              "Real Estate Property Management" => "Real Estate - Property Management",
                              "Real Estate Title Companies" => "Real Estate - Title Companies",
                              # "SCHOOLS" => "",
                              "Tax Return Preparation and Filing" => "Tax Preparation"
                             ]
                             
  
  def self.normalize(s)
    s.split.map do |s|
      case
      when ['and', '&'].include?(s.downcase)
        'and'
      when s == '-'
        '-'
      else
        s.strip.titleize
      end
    end.join(" ")
  end
  
  def self.to_tag_group(s)
    s  = normalize(s)
    tg = TagGroup.find_by_name(s)
    return tg if tg

    # map string to a tag group name
    s_mapped = @@tag_group_mappings[s]
    
    TagGroup.find_by_name(s_mapped)
  end
end