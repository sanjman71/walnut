namespace :database do
  
  desc "Configure database.yml"
  task :configure, :roles => :app do
    puts "copying database.yml"
    sudo "cp #{release_path}/config/templates/database.#{rails_env}.yml #{release_path}/config/database.yml"
  end

end