class LocationNeighborCollection < ::Array
  
  def each_with_geodist(&block)
    self.each_with_index do |location_neighbor, index|
      yield location_neighbor.neighbor, location_neighbor.distance
    end
  end

end