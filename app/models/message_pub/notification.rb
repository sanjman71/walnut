module MessagePub
  require 'rubygems'
  require 'activeresource'

  class Notification < ActiveResource::Base
    # Remember to put in your API key.
    self.site = "http://92893db8e580a4178ca4745c8106300b1ebf132f@messagepub.com/"
  end
end