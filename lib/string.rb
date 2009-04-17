class String
  def from_url_param
    gsub('-', ' ')
  end
end