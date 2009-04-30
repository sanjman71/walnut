module Localeze
  
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

    # find all unique categories
    def categories
      (categories1 + categories2).uniq 
    end

    # structured attributes collection
    def attributes
      company_attributes
      # company_attributes + company_unstructured_attributes
    end

    # def tags
    #   # just use categories
    #   @tags ||= categories.collect{ |o| o.tags }.flatten.uniq
    # end

    # condensed and normalized details collection
    # def details
    #   condensed_details + normalized_details
    # end

  end
  
end