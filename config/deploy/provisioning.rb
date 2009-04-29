
# #######################################
# HOSTING PROVIDER CONFIGURATION
# Those tasks have been tested with several hosting providers
# and sometimes tasks are specific to those providers
set :hosting_provider, "ec2" # currently supported : ovh-rps, ovh-dedie, slicehost

# #######################################
# SERVER CONFIGURATION
# set :server_name, "YOUR_SERVER_NAME_HERE"
set :root_user, 'root'

# set :user, 'peanut'
set :setup_ssh, false # makes admin user not able to use ssh
ssh_options[:port] = 22

# #######################################
# LOCAL CONFIGURATION
ssh_options[:keys] = "/Users/killian/.ec2/id_rsa-kdefault"
set :default_local_files_path, "/Users/killian/Desktop"

# #######################################
# SOFTWARE INSTALL CONFIGURATION

# SOFTWARE INSTALLATION OPTIONS
set :install_curl, true

set :install_mysql, true
set :mysql_use_ebs, "vol-id" # For use with Amazon AWS EBS

# Don't install apache or nginx - nginx will be installed with passenger later
set :install_apache, false
set :install_nginx, false # Don't install nginx here if want to use passenger with it - the passenger installer will build nginx
# Don't install ruby - It's already there, and we want to use REE anyway
set :install_ruby, false
set :install_rubygems, true
set :install_ruby_enterprise, false
set :gem_path, "/usr/bin/"

# Install passenger
set :install_passenger, true
set :passenger_use_nginx, true # If you use nginx here, don't install it above - passenger will rebuild nginx from scratch
set :passenger_use_apache, false

# Install git
set :install_git, true

# Don't need php
set :install_php, false

# Install memcached
set :install_memcached, true

# Install Sphinx
set :install_sphinx, true
set :sphinx_use_ebs, "vol-id" # For use with Amazon AWS EBS

# Install additional packages
set :configure_apparmor, false # necessary to allow MySQL to bulk import from /u/apps/
set :install_imagemagick, true
set :install_god, true

# version numbers
# NOTE: The latest version of Ruby Enterprise Edition is used unless you specify a version below.
# set :ruby_enterprise_version, "ruby-enterprise-1.8.6-20090113"
set :rubygem_version, "1.3.2"
set :passenger_version, "2.2.1"
set :git_version, "git-1.6.0.6"
set :sphinx_version, "sphinx-0.9.9-rc1"

# some Apache default values
set :default_server_admin, "killian@killianmurphy.com"
set :default_directory_index, "index.html"

# EBS setup
set :mysql_block_mnt, "/dev/sdm"
set :mysql_vol_id, "vol-1710f37e"
set :mysql_mount_pt, "/vol/mysql"
set :mysql_dir_root, "/vol/mysql"

after "machine:install_dev_tools", "mysql:ebs"

set :sphinx_block_mnt, "/dev/sds"
set :sphinx_vol_id, "vol-631bf80a"
set :sphinx_mount_pt, "/vol/sphinx"
set :sphinx_dir_root, "/vol/sphinx"

after "machine:install_dev_tools", "sphinx:ebs"

# Role definitions
role :gateway,  server_name
role :app,      server_name
role :web,      server_name
role :db,       server_name, :primary => true
