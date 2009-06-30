module ActiveSupport
  module SecureRandom
    
    # Generates a random base64 string that does not start with '/'
    def self.base64(n=nil)
      s = [random_bytes(n)].pack("m*").delete("\n")
      i = 1
      while s.match(/^\//) and i < 3
        s = [random_bytes(n)].pack("m*").delete("\n")
        i += 1
      end
      s
    end
    
  end
end