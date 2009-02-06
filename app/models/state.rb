class State < ActiveRecord::Base
  validates_presence_of       :name, :code, :country_id
  validates_uniqueness_of     :name
  belongs_to                  :country
  has_many                    :areas, :as => :extent
  has_many                    :cities
  
  def to_param
    self.code.downcase
  end
end
