class Country < ActiveRecord::Base
  validates_presence_of       :name, :ab
  validates_uniqueness_of     :name
  has_many                    :areas, :as => :extent
end