namespace :nginx do
  
  desc "Stop nginx"
  task :stop, :roles => :app do
    sudo "god stop nginx"
  end

  desc "Start nginx"
  task :start, :roles => :app do
    sudo "god start nginx"
  end

  desc "Restart nginx"
  task :restart, :roles => :app do
    sudo "god restart nginx"
  end
  
  desc "Reload nginx configuration file"
  taks :reload, :roles => :app do
    sudo "/etc/init.d/nginx reload"
  end
  
end