# Create hosts hash, especially useful when there is more than 1 host
hosts                   = Hash.new
hosts[:cloud_servers]   = '67.23.46.244:30001'

# Set roles
role :app,          hosts[:cloud_servers]
role :web,          hosts[:cloud_servers]
role :db,           hosts[:cloud_servers], :primary => true

# Set rails environment
set :rails_env,     'production'
