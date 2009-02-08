class Zip < ActiveRecord::Base
  validates_presence_of       :name, :state_id
  validates_format_of         :name, :with => /\d{5,5}/
  validates_uniqueness_of     :name, :scope => :state_id
  belongs_to                  :state
  has_many                    :areas, :as => :extent
  has_many                    :city_zips
  has_many                    :cities, :through => :city_zips
  
  def to_param
    self.name
  end
  
  def to_s
    self.name
  end
end
