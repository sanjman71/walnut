namespace :database do
  
  desc "Configure database.yml"
  task :configure, :roles => :app do
    puts "copying database.yml"
    sudo "cp #{current_release}/config/templates/database.#{rails_env}.yml #{current_release}/config/database.yml"
  end

end