class City < ActiveRecord::Base
  validates_presence_of       :name, :state_id
  validates_uniqueness_of     :name, :scope => :state_id
  belongs_to                  :state
  has_many                    :areas, :as => :extent
  has_many                    :city_zips
  has_many                    :zips, :through => :city_zips
  has_many                    :neighborhoods
  
  # the special anywhere object
  def self.anywhere(state=nil)
    City.new do |o|
      o.name      = "Anywhere"
      o.state_id  = state.id if state
      o.send(:id=, 0)
    end
  end
  
  def anywhere?
    self.id == 0
  end
  
  def to_param
    self.name.downcase.gsub(' ', '-')
  end
  
  def to_s
    self.name
  end
end
