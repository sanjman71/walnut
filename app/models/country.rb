class Country < ActiveRecord::Base
  validates_presence_of       :name, :code
  validates_uniqueness_of     :name
  has_many                    :areas, :as => :extent
  has_many                    :states
  
  def self.default
    @@country ||= Country.find_by_code("US")
  end
  
  def to_s
    self.name
  end
  
  def to_param
    self.code.downcase
  end
end