class State < ActiveRecord::Base
  validates_presence_of       :name, :ab, :country_id
  validates_uniqueness_of     :name
  belongs_to                  :country
  has_many                    :areas, :as => :extent
end
