class Area < ActiveRecord::Base
  belongs_to                :extent, :polymorphic => true
  validates_presence_of     :extent_id, :extent_type
  validates_uniqueness_of   :extent_id, :scope => :extent_type

  acts_as_mappable
  
  def self.resolve(s)
    begin
      geoloc = geocode(s)
      
      if geoloc.provider == 'google'
        case geoloc.precision
        when 'country'
          # find database object
          object = Country.find_by_code(geoloc.country_code)
        when 'state'
          # find database object, geoloc state is the state code, e.g. "IL"
          object = State.find_by_code(geoloc.state)
        when 'city'
          # find state database object
          state   = State.find_by_code(geoloc.state)
          # find city from state
          object  = state.cities.find_by_name(geoloc.city)
        when 'zip'
          # find state database object
          state   = State.find_by_code(geoloc.state)
          # find zip from state
          object  = state.zips.find_by_name(geoloc.zip)
        end
        
        return object
      end
    rescue
      return nil
    end
    
    return nil
  end
  
end