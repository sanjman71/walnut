class State < ActiveRecord::Base
  validates_presence_of       :name, :code, :country_id
  validates_uniqueness_of     :name
  belongs_to                  :country
  has_many                    :cities
  has_many                    :zips
  
  def to_param
    self.code.downcase
  end
  
  def to_s
    self.name
  end
end
