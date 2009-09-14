class String
  def to_url_param
    gsub(/[^a-z0-9\-_\+]+/i, '-').downcase
  end

  def from_url_param
    gsub('-', ' ')
  end
end