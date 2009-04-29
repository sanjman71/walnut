namespace :rails do

  def user_copy_git_keys(user)
    
    if git_key.size != ""
      homedir = capture("cd ~#{user}; pwd").strip
      sudo "mkdir -p #{homedir}/.ssh"

      priv_key = File.read("#{git_key}")
      pub_key = File.read("#{git_key}.pub")

      put priv_key, "/tmp/id_rsa"
      put pub_key, "/tmp/id_rsa.pub"
      sudo "mv /tmp/id_rsa* #{homedir}/.ssh/"
      sudo "chown -R #{user}:#{user} #{homedir}/.ssh"
      sudo "chmod 600 #{homedir}/.ssh/id_rsa"
      sudo "chmod 600 #{homedir}/.ssh/id_rsa.pub"
      sudo "chmod 700 #{homedir}/.ssh"
    end
  end
  
  desc "Copy our git keys so that we can clone the repository"
  task :copy_git_keys, :roles => :app do
    user_copy_git_keys(user)
    user_copy_git_keys("root")
  end
  
  desc "remotely console" 
  task :console, :roles => :app do
    input = ''
    run "cd #{current_path} && ./script/console #{ENV['RAILS_ENV']}" do |channel, stream, data|
      next if data.chomp == input.chomp || data.chomp == ''
      print data
      channel.send_data(input = $stdin.gets) if data =~ /^(>|\?)>/
    end
  end
  
  desc "Add the github.com host to the authorized hosts file"
  task :add_github_authorized do
    run "ssh git@github.com" do |channel, stream, data|
      print data
      channel.send_data("yes\n")
    end
    # sudo "ssh git@github.com"
  end

  desc "Install the required gems"
  task :install_gems, :roles => :app do
    gems_to_install.each do |gem|
      sudo "#{gem_path}gem install #{gem} --no-rdoc --no-ri"
    end
    # run "cd #{current_path} && rake gems:install RAILS_ENV=#{rails_env}"
  end

  desc "Install Rails"
  task :install_rails, :roles => :app do
    sudo "#{gem_path}gem install rails -v#{rails_version} --no-rdoc --no-ri"
  end

  desc "Set the owner of the app directory"
  task :set_app_dir_owner, :roles => :app do
    sudo "chown -R #{user}:#{user} #{deploy_to}"
  end
  
end
