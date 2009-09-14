class Country < ActiveRecord::Base
  validates_presence_of       :name, :code
  validates_uniqueness_of     :name
  has_many                    :states
  has_many                    :locations
  
  include NameParam

  attr_accessible             :name, :code

  def self.default
    @@country ||= self.us
  end

  def self.us
    Country.find_by_code("US")
  end

  def to_param
    self.code.downcase
  end

end