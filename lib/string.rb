class String
  def to_url_param
    gsub(' ', '-')
  end

  def from_url_param
    gsub('-', ' ')
  end
end