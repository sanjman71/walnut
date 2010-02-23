require 'google_weather'

class Weather
  attr_reader :current_condition, :current_temp, :current_icon, 
              :forecast_today_day_of_week, :forecast_today_condition, :forecast_today_temp_low, :forecast_today_temp_high, :forecast_today_icon,
              :name

  def initialize(google_weather, name)
    @google_weather = google_weather
    
    # initialize data members
    @current_condition  = @google_weather.current_conditions.condition
    @current_temp       = @google_weather.current_conditions.temp_f
    @current_icon       = "http://www.google.com#{@google_weather.current_conditions.icon}"
    
    @forecast_today_day_of_week = @google_weather.forecast_conditions[0].day_of_week
    @forecast_today_condition   = @google_weather.forecast_conditions[0].condition
    @forecast_today_temp_low    = @google_weather.forecast_conditions[0].low
    @forecast_today_temp_high   = @google_weather.forecast_conditions[0].high
    @forecast_today_icon        = "http://www.google.com#{@google_weather.forecast_conditions[0].icon}"

    @name = name
  end
  
  def self.get(city_state_or_zip, name)
    begin
      # just in case the google weather api throws an exception
      w = Weather.new(GoogleWeather.new(city_state_or_zip), name)
    rescue Exception => e
      w = nil
    end

    w
  end

  @@weather_cities = City.min_density(25000).order_by_density

  # return list of weather enabled cities
  def self.cities
    @@weather_cities
  end

  # returns true if the specified city is a weather city
  def self.city?(o)
    return false if o.blank? or !o.is_a?(City)
    cities.include?(o)
  end

  # returns true if the specified zip is a weather zip
  def self.zip?(o)
    return false if o.blank? or !o.is_a?(Zip)
    # map zip to city, and check city
    city?(o.city)
  end

end