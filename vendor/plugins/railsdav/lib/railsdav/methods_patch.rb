module ActionController
  if Rails.version >= "2.3.0"
    class Request
      HTTP_METHODS = %w(get head put post delete options lock unlock propfind proppatch mkcol delete put copy move userinfo)
      HTTP_METHOD_LOOKUP = HTTP_METHODS.inject({}) { |h, m| h[m] = h[m.upcase] = m.to_sym; h }
    end
  else
    class AbstractRequest
      HTTP_METHODS = %w(get head put post delete options lock unlock propfind proppatch mkcol delete put copy move userinfo)
      HTTP_METHOD_LOOKUP = HTTP_METHODS.inject({}) { |h, m| h[m] = h[m.upcase] = m.to_sym; h }
    end
  end
end
