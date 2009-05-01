class Hash
  def compact!
    delete_if {|key, value| value.blank?}
  end

  def compact
    dup.compact!
  end
end