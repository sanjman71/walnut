# use the ubuntu machine gem
require 'capistrano/ext/ubuntu-machine'

# Add our local deployment scripts directory
load_paths << "config/deploy"

# Assuming you have just one ec2 server, set it's public DNS name here:
set :server_name, "ec2-174-129-88-81.compute-1.amazonaws.com"
set :ec2_instance_id, "i-f01e7499"

# Be explicit about our different environments
# set :stages, %w(staging production)
require 'capistrano/ext/multistage'

# Set application name
set :application,   "peanut"

# If you aren't deploying to /u/apps/#{application} on the target
# servers (which is the default), you can specify the actual location
# via the :deploy_to variable:
set :deploy_to,     "/usr/apps/#{application}"

# Git repository
set :scm,           :git
set :repository,    'git@github.com:sanjman71/peanut.git'
set :branch,        "peanutec2"
set :deploy_via,    :remote_cache

# Users, groups
set :user,          'peanut'  # log into servers as
set :group,         'peanut'

set :runner,        'peanut'

# We want to install rails v2.3.2 as part of setup
set :rails_version, "2.3.2"

# We need to copy our git keys over to the machine as part of setting up, before we try to clone the repository
set :git_key, "/Users/killian/.ssh/id_rsa-github-ec2" # the path to the key file to use with git, e.g. "~/.ssh/id_rsa-git"

set :gems_to_install, [
  'mbleigh-subdomain-fu --source=http://gems.github.com',
  "chronic",
  "haml",
  "starling",
  'rubyist-aasm --source=http://gems.github.com',
  'mislav-will_paginate --source=http://gems.github.com',
  'sanitize',
  'prawn',
  'populator',
  'faker',
  'thoughtbot-factory_girl --source http://gems.github.com'
  ]

# We want to use a separate user with sudo privileges
# set :admin_runner, 'admin'

# Load data for provisioning resources
load "provisioning"

# Load some tasks for setting up rails
load "rails_tasks"

# Load some tasks for hooking in god
load "god_tasks"

# Load tasks for configuring the database
load "database_tasks"

before "deploy:setup", "rails:install_rails"
before "deploy:setup", "rails:copy_git_keys"
after "deploy:setup", "god:start_mysql"
after "deploy:setup", "rails:set_app_dir_owner"

after "deploy:update_code", "database:configure"
after "deploy:symlink", "rails:install_gems"
after "deploy", "god:start_god"
