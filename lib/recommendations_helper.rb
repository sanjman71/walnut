module RecommendationsHelper
  protected

  # return true if the location has been recommended
  def recommended?(location)
    return location.recommendations_count > 0
  end
  
  # return true if the location has been recommended
  def recommended_by_me?(location)
    return false if session[:recommendations].blank?
    session[:recommendations].include?(location.id)
  end
  
  # cache the location recommendation in the session
  def cache_recommendation(location)
    my_recommendations = session[:recommendations] || Set.new
    my_recommendations.add(location.id)
    session[:recommendations] = my_recommendations
  end
  
end