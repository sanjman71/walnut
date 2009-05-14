class Array
  
  def zero_compact!
    delete_if { |o| o.blank? or o == 0 }
  end
  
  def zero_compact
    dup.zero_compact!
  end
  
end