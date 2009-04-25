# Be explicit about our different environments
set :stages, %w(staging production)
require 'capistrano/ext/multistage'

# Set application name
set :application,   "walnut"

# If you aren't deploying to /u/apps/#{application} on the target
# servers (which is the default), you can specify the actual location
# via the :deploy_to variable:
set :deploy_to,     "/usr/apps/#{application}"

# Git repository
set :scm,           :git
set :repository,    'git@github.com:sanjman71/walnut.git'
set :branch,        "master"
set :deploy_via,    :remote_cache

# Users, groups
set :user,          'app'  # log into servers as
set :group,         'app'

# Load external recipe files
load_paths << "config/database"
load "database_tasks"
load_paths << "config/sphinx"
load "sphinx_tasks"
