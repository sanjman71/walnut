module Localeze
  class NormalizedDetail <ActiveRecord::Base
    establish_connection("localeze_#{RAILS_ENV}")
    validates_presence_of :name
  end
end