namespace :sphinx do
  
  desc "Create the sphinx shared index directory"
  task :shared, :roles => :app do
    puts "creating sphinx index directory"
    run "mkdir #{shared_path}/sphinx"
  end

  desc "Create the sphinx config file"
  task :configure, :roles => :app do
    run "cd #{current_path}; rake ts:config RAILS_ENV=#{rails_env}"
  end

  desc "Stop the sphinx searchd daemon"
  task :stop, :roles => :app do
    run "cd #{current_path}; rake ts:stop RAILS_ENV=#{rails_env}"
  end

  desc "Start the sphinx searchd daemon"
  task :start, :roles => :app do
    run "cd #{current_path}; rake ts:start RAILS_ENV=#{rails_env}"
  end

  desc "Restart the sphinx searchd daemon"
  task :restart, :roles => :app do
    # stop and then start; restart doesn't work properly
    stop
    sleep(3)
    start
  end

end