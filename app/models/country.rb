class Country < ActiveRecord::Base
  validates_presence_of       :name, :code
  validates_uniqueness_of     :name
  has_many                    :states
  has_many                    :addresses

  include NameParam
  
  def self.default
    @@country ||= Country.find_by_code("US")
  end
  
end