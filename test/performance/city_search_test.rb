require 'test_helper'
require 'performance_test_help'

class CitySearchTest < ActionController::PerformanceTest
  def test_city_search
    get '/search/us/il/chicago/tag/something'
  end
end
