# Settings specified here will take precedence over those in config/environment.rb

# In the development environment your application's code is reloaded on
# every request.  This slows down response time but is perfect for development
# since you don't have to restart the webserver when you make code changes.
config.cache_classes = false

# Log error messages when you accidentally call methods on nil.
config.whiny_nils = true

# Show full error reports and disable caching
config.action_controller.consider_all_requests_local = true
config.action_view.debug_rjs                         = true
config.action_controller.perform_caching             = true

# Don't care if the mailer can't send
config.action_mailer.raise_delivery_errors = false

# Configure the rails cache
# config.cache_store = :file_store, "#{RAILS_ROOT}/tmp/cache"
config.cache_store = :mem_cache_store

# Google maps api key - http://www.walnut.dev
GOOGLE_MAPS_API_KEY = "ABQIAAAAomTSMjVMlOfQaldkZBqMBBRKHyjCFHczuSNpLv6PJ7BM1sjczBSR9dLPitiritgQPAQhDKJM7I0E9g"
GOOGLE_MAPS_API_URL = "http://maps.google.com/maps?file=api&amp;v=2&amp;key=#{GOOGLE_MAPS_API_KEY}"

# Blueprint grid only in development environment
$BlueprintGrid = false
