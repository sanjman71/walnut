require "#{File.dirname(__FILE__)}/object/conversions.rb"

class Object #:nodoc:
  #- ©2009 Rick DeNatale
  #- All rights reserved. Refer to the file README.txt for the license
  #
  include RiCal::CoreExtensions::Object::Conversions
end