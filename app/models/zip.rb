class Zip < ActiveRecord::Base
  validates_presence_of       :name, :state_id
  validates_format_of         :name, :with => /\d{5,5}/
  validates_uniqueness_of     :name, :scope => :state_id
  belongs_to                  :state, :counter_cache => true
  has_many                    :city_zips
  has_many                    :cities, :through => :city_zips
  has_many                    :locations
  
  include NameParam

  # find zips with locations
  named_scope :with_locations,        { :conditions => ["locations_count > 0"] }
  
  # order zips by location count
  named_scope :order_by_density,      {:order => "zips.locations_count DESC"}


  def self.to_csv
    csv = Zip.all.collect do |zip|
      "#{zip.id}|#{zip.name}|#{zip.state_id}|#{zip.lat}|#{zip.lng}"
    end
  end
    
end
