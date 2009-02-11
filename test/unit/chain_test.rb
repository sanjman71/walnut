require 'test/factories'

class ChainTest < ActiveSupport::TestCase
  
  should_require_attributes   :name
  should_have_many            :places

end