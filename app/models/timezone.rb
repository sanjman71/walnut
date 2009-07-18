class Timezone < ActiveRecord::Base
  validates_presence_of   :name, :utc_offset

  has_many                :cities
  has_many                :zips
  has_many                :companies
  has_many                :locations
end