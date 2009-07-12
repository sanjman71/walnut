module Localeze
  
  require 'fastercsv'
  
  class BaseRecord < ActiveRecord::Base
    establish_connection("localeze_#{RAILS_ENV}")
    belongs_to    :chain, :class_name => "Localeze::Chain"
    has_many      :company_headings, :class_name=> "Localeze::CompanyHeading"
    has_many      :categories1, :through => :company_headings, :source => :category, :class_name => "Localeze::Category"
    has_many      :condensed_details, :through => :company_headings
    has_many      :normalized_details, :through => :company_headings

    # custom attributes include email, url fields
    has_many      :custom_attributes, :class_name => "Localeze::CustomAttribute"

    # company attributes are structured attributes, e.g. brands, cusines, menu items
    has_many      :company_attributes, :class_name => "Localeze::CompanyAttribute"
    has_many      :categories2, :through => :company_attributes, :source => :category, :class_name => "Localeze::Category"

    # these are unstructured and usually added by the company
    has_many      :company_unstructured_attributes, :class_name => "Localeze::CompanyUnstructuredAttribute"

    # payment types accepted, e.g. "Mastercard", "Visa"
    has_many      :company_payment_types, :class_name => "Localeze::CompanyPaymentType"

    has_many      :company_phones, :class_name => "Localeze::CompanyPhone"


    # city corrections file
    @@city_corrections  = nil
    
    def street_address
      [housenumber, predirectional, streetname, streettype, postdirectional, apttype, aptnumber].reject(&:blank?).join(" ")
    end
    
    def phone_number
      return nil if areacode.blank? or exchange.blank? or phonenumber.blank?
      [areacode, exchange, phonenumber].join
    end
    
    # returns true iff the base record has a latitude and longitude 
    def mappable?
      return true if self.latitude and self.longitude
      false
    end

    def dnc?
      self.dnc == 'N'
    end

    # find all unique categories
    def categories
      (categories1 + categories2).uniq 
    end

    # structured attributes collection
    def attributes
      company_attributes
      # company_attributes + company_unstructured_attributes
    end

    # fix localeze city errors
    # note: these errors have been collected after running many imports
    def apply_city_corrections
      new_city  = self.class.apply_city_corrections(self.city, self.state)
      
      if new_city != self.city
        # apply change, but don't save record
        self.city = new_city
        # self.save
        1
      else 
        0
      end
    end
    
    def self.apply_city_corrections(city, state_code)
      hash    = self.load_city_corrections
      errors  = 0
      
      return errors if !hash.has_key?(state_code)
      
      hash[state_code].each_pair do |wrong_city, right_city|
        if city == wrong_city
          # fix city
          return right_city
        end
      end

      # no change applied
      city
    end
    
    # def tags
    #   # just use categories
    #   @tags ||= categories.collect{ |o| o.tags }.flatten.uniq
    # end

    # condensed and normalized details collection
    # def details
    #   condensed_details + normalized_details
    # end

    protected

    def self.load_city_corrections
      if @@city_corrections.blank?
        hash = Hash.new({})
        file = "#{RAILS_ROOT}/vendor/plugins/localeze/data/city_corrections.txt"

        FasterCSV.foreach(file, :col_sep => '|') do |row|
          next if row.blank?
          state_code, wrong_city, right_city = row
          hash[state_code] = hash[state_code].merge(wrong_city.strip => right_city.strip)
        end

        @@city_corrections = hash
      end
      
      @@city_corrections
    end

  end
  
end