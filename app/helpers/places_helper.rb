module PlacesHelper

  def city_state_zip(city, state, zip)
    [city ? "#{city.name}," : "", state ? state.name : "", zip ? zip.name : ""].compact.join(" ")
  end
  
end
