# Be sure to restart your server when you modify this file

# Uncomment below to force Rails into production mode when
# you don't control web/app server and can't set it the proper way
# ENV['RAILS_ENV'] ||= 'production'

# Specifies gem version of Rails to use when vendor/rails is not present
# Note: use 2.3.3 with ruby 1.9 - https://rails.lighthouseapp.com/projects/8994-ruby-on-rails/tickets/3144-undefined-method-for-string-ror-234
RAILS_GEM_VERSION = '2.3.3' unless defined? RAILS_GEM_VERSION  

# Bootstrap the Rails environment, frameworks, and default configuration
require File.join(File.dirname(__FILE__), 'boot')

Rails::Initializer.run do |config|
  # Settings in config/environments/* take precedence over those specified here.
  # Application configuration should go into files in config/initializers
  # -- all .rb files in that directory are automatically loaded.
  # See Rails::Configuration for more options.

  # Skip frameworks you're not going to use. To use Rails without a database
  # you must remove the Active Record framework.
  # config.frameworks -= [ :active_record, :active_resource, :action_mailer ]

  # Specify gems that this application depends on. 
  # They can then be installed with "rake gems:install" on new installations.
  # You have to specify the :lib option for libraries, where the Gem name (sqlite3-ruby) differs from the file itself (sqlite3)
  config.gem "ar-extensions", :version => "~> 0.9.2"
  config.gem "chronic", :version => '~> 0.2.3' # required by javan-whenever
  config.gem "crack", :version => "~> 0.1.4" # required by google weather
  config.gem "curb", :version => "~> 0.5.1" # curl api; requires native components
  config.gem "daemons", :version => '~> 1.0.10'
  config.gem "eventfulapi", :lib => false
  # config.gem "fastercsv"  # built into ruby 1.9
  config.gem "geokit" # required by geokit-rails plugin
  config.gem "haml", :version => '~> 2.2.4'
  config.gem "httparty", :lib => false # used by google weather plugin
  config.gem "json", :version => '~> 1.1.7' # requires native components
  config.gem 'mechanize', :version => '0.9.3'
  config.gem "mime-types", :lib => false
  config.gem 'mislav-will_paginate', :version => '~> 2.3.6', :lib => 'will_paginate', :source => "http://gems.github.com"
  config.gem 'ri_cal', :version => '~> 0.8.1'
  config.gem 'rubyist-aasm', :version => '~> 2.1.1', :lib => 'aasm', :source => "http://gems.github.com"
  config.gem 'whenever', :version => '0.4.1', :lib => false, :source => 'http://gemcutter.org/'
  
  # Only load the plugins named here, in the order given. By default, all plugins 
  # in vendor/plugins are loaded in alphabetical order.
  # :all can be used as a placeholder for all plugins not explicitly named
  # config.plugins = [ :exception_notification, :ssl_requirement, :all ]

  # Add additional load paths for your own custom dirs
  config.load_paths += %W( #{RAILS_ROOT}/lib/jobs )

  # Prevent the lib directory from being reloaded
  # Avoid the problem: A copy of AuthenticatedSystem has been removed from the module tree but is still active!
  config.load_once_paths += %W( #{RAILS_ROOT}/lib )

  # Force all environments to use the same logger level
  # (by default production uses :info, the others :debug)
  # config.log_level = :debug

  # Make Time.zone default to the specified zone, and make Active Record store time values
  # in the database in UTC, and return them converted to the specified local zone.
  # Run "rake -D time" for a list of tasks for finding time zone names. Comment line to use default local time.
  config.time_zone = 'UTC'

  # The internationalization framework can be changed to have another default locale (standard is :en) or more load paths.
  # All files from config/locales/*.rb,yml are added automatically.
  # config.i18n.load_path << Dir[File.join(RAILS_ROOT, 'my', 'locales', '*.{rb,yml}')]
  # config.i18n.default_locale = :de

  # Your secret key for verifying cookie session data integrity.
  # If you change this key, all old sessions will become invalid!
  # Make sure the secret is at least 30 characters and all random, 
  # no regular words or you'll be exposed to dictionary attacks.
  config.action_controller.session = {
    :session_key => '_walnut_session',
    :secret      => '99ba0c35d4daae582395420ba9012628abb6080f1aed88831eb10b177e133a68428fbcdb0e51b8e508f5b3be14d391c4f1333322ea7be1b7e422c89039e8aab2'
  }

  # Use the database for sessions instead of the cookie-based default,
  # which shouldn't be used to store highly confidential information
  # (create the session table with "rake db:sessions:create")
  # config.action_controller.session_store = :active_record_store

  # Use SQL instead of Active Record's schema dumper when creating the test database.
  # This is necessary if your schema can't be completely dumped by the schema dumper,
  # like if you have constraints or database-specific column types
  # config.active_record.schema_format = :sql

  # Activate observers that should always be running
  # Please note that observers generated using script/generate observer need to have an _observer suffix
  # config.active_record.observers = :cacher, :garbage_collector, :forum_observer
  
  # Turn off timestamped migrations
  config.active_record.timestamped_migrations = false

end

# Extend ruby classes
require "#{RAILS_ROOT}/lib/string.rb"
require "#{RAILS_ROOT}/lib/hash.rb"
require "#{RAILS_ROOT}/lib/math.rb"
require "#{RAILS_ROOT}/lib/array.rb"
require "#{RAILS_ROOT}/lib/secure_random.rb"
require "#{RAILS_ROOT}/lib/time_calculations.rb"

# RPX key
RPXNow.api_key = "486f794f3a5473f9b5d3b08d1d43c9aa3c7e5872"

# Admin users email collection
ADMIN_USER_EMAILS  = %w(sanjay@walnutindustries.com killian@walnutindustries.com)

# Auth token
AUTH_TOKEN_INSTANCE = "5e722026ea70e6e497815ef52f9e73c5ddb8ac26"

# Application logger level used for benchmark logging purposes
APP_LOGGER_LEVEL  = ActiveRecord::Base.logger.level

# Initialize exception notifier
ExceptionNotifier.exception_recipients  = %w(exceptions@walnutindustries.com)
ExceptionNotifier.sender_address        = %("Walnut Places Exception" <app@walnutindustries.com>)
ExceptionNotifier.email_prefix          = "Walnut Places "

# Weather enabled environments
WEATHER_ENVS = ['development']

# Application SMTP provider; valid options are :google, :message_pub
SMTP_PROVIDER = :google
SMTP_FROM     = "Walnut Messaging <messaging@walnutindustries.com>"

# create special localeze loggers
LOCALEZE_ERROR_LOGGER     = Logger.new("log/localeze.error.log")
LOCALEZE_DELTA_LOGGER     = Logger.new("log/localeze.delta.log")
DATA_ERROR_LOGGER         = Logger.new("log/data.error.log")
DATA_TAGS_LOGGER          = Logger.new("log/data.tags.log")
