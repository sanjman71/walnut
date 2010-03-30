module PlacesHelper

  def display_address(location)
    return "" if location.blank?
    [location.street_address, city_state_zip(location.city, location.state, location.zip)].reject(&:blank?).join("<br/>")
  end

  def city_state_zip(city, state, zip)
    [city ? "#{city.name}," : "", state ? state.code : "", zip ? zip.name : ""].compact.join(" ")
  end
  
end
