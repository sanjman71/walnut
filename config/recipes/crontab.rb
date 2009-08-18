# Capistrano Recipes for managing crontab

namespace :crontab do
  desc "Update crontab"
  task :update, :roles => :app do
    run "cd #{current_path}; whenever --update-crontab #{application}"
  end
end