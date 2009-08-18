class AuthToken
  include Singleton

  def token
    AUTH_TOKEN_INSTANCE
  end
end