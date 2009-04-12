module TagsHelper
  # convert object to a class (e.g. 'one', 'two', 'three') based on its relative count
  def tag_cloud_class(object, count_method, max_count, klasses)
    i = ((object.send(count_method).to_f / max_count.to_f) * klasses.size).ceil
    # convert integer to string
    klasses[i-1]
  end
end