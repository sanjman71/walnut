# Create hosts hash, especially useful when there is more than 1 host
# hosts               = Hash.new
# hosts[:slicehost]   = '173.45.229.171:30001'
# 
# # Set roles
# role :app,          hosts[:slicehost]
# role :web,          hosts[:slicehost]
# role :db,           hosts[:slicehost], :primary => true

# Set rails environment
set :rails_env,     'production'
