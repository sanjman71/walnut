# Settings specified here will take precedence over those in config/environment.rb

# The production environment is meant for finished, "live" apps.
# Code is not reloaded between requests
config.cache_classes = true

# Enable threaded mode
# config.threadsafe!

# Use a different logger for distributed setups
# config.logger = SyslogLogger.new

# Full error reports are disabled and caching is turned on
config.action_controller.consider_all_requests_local = false
config.action_controller.perform_caching             = true

# Use a different cache store in production
# config.cache_store = :mem_cache_store

# Enable serving of images, stylesheets, and javascripts from an asset server
# config.action_controller.asset_host                  = "http://assets.example.com"

# Disable delivery errors, bad email addresses will be ignored
# config.action_mailer.raise_delivery_errors = false

# Google maps api key - http://www.walnut.dev
GOOGLE_MAPS_API_KEY = "ABQIAAAAomTSMjVMlOfQaldkZBqMBBQ_iVWkfahRx28F601hjowthm7xKBTBIas46h18ghWQEh_aYdV9ICVtng"
GOOGLE_MAPS_API_URL = "http://maps.google.com/maps?file=api&amp;v=2&amp;key=#{GOOGLE_MAPS_API_KEY}"

