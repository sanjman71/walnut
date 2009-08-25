# Create hosts hash, especially useful when there is more than 1 host
hosts               = Hash.new
hosts[:mosso]       = '174.143.204.171'

# Set roles
role :app,          hosts[:mosso]
role :web,          hosts[:mosso]
role :db,           hosts[:mosso], :primary => true

# Set rails environment
set :rails_env,     'production'
