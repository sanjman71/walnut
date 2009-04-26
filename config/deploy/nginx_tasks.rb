namespace :nginx do
  
  desc "Initialize the nginx configuration files"
  task :config, :roles => :app do
    homedir = capture("cd ~#{user}; pwd").strip
    nginx_conf = File.read("config/templates/nginx.conf")
    site_conf = File.read("config/templates/www.walnutplaces.com")

    put nginx_conf, "#{homedir}/nginx.conf"
    put site_conf, "#{homedir}/www.walnutplaces.com"
    sudo "mv /opt/nginx/conf/nginx.conf /opt/nginx/conf/nginx.conf.old"
    sudo "mv #{homedir}/nginx.conf /opt/nginx/conf/nginx.conf"
    sudo "mv #{homedir}/www.walnutplaces.com /opt/nginx/conf/www.walnutplaces.com"
    sudo "chown -R #{user}:#{user} /opt/nginx"
  end
  
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
  task :reload, :roles => :app do
    sudo "/etc/init.d/nginx reload"
  end
  
end