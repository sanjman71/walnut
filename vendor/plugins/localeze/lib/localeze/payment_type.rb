module Localeze
  class PaymentType <ActiveRecord::Base
    establish_connection("localeze_#{RAILS_ENV}")
  end
end