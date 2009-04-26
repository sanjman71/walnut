namespace :deploy do

  task :start do
    sudo "god start nginx"
  end
  
  task :restart do
    sudo "god restart nginx"
  end
  
  task :stop do
    sudo "god stop nginx"
  end
  
end

namespace :god do
  
  task :start_mysql do
    sudo "/etc/init.d/mysql start"
  end
  
  task :start_god do
    run "cp #{current_path}/config/templates/user.#{rails_env}.yml #{current_path}/config/god/user.yml"
    sudo "god -c #{current_path}/config/#{application}.god"
  end
  
end
