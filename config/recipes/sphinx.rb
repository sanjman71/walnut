namespace :sphinx do
  
  desc "Configure sphinx, e.g. shared index directory"
  task :configure, :roles => :app do
    puts "creating sphinx index directory"
    run "mkdir #{shared_path}/sphinx"
  end

end