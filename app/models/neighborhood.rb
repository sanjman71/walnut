class Neighborhood < ActiveRecord::Base
  validates_presence_of       :name, :city_id
  validates_uniqueness_of     :name, :scope => :city_id
  belongs_to                  :city, :counter_cache => true
  has_many                    :localities, :as => :extent

  include NameModule

end
