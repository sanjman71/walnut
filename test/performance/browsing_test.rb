require 'test_helper'
require 'performance_test_help'

# Profiling results for each test method are written to tmp/performance.
class BrowsingTest < ActionController::PerformanceTest
  def test_homepage
    get '/'
  end
  
  def test_chicago_places
    get '/places/us/il/chicago'
  end
  
  def test_chicago_events
    get '/events/us/il/chicago'
  end
  
  def test_chicago_something
    get '/places/us/il/chicago/something'
  end
end
