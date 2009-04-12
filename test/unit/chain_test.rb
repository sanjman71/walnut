require 'test/test_helper'
require 'test/factories'

class ChainTest < ActiveSupport::TestCase
  
  should_validate_presence_of   :name
  should_have_many              :places

end