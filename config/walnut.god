# Start with: 'sudo god -c config/walnut.god'
require 'yaml'

# Application directory in production
walnut_dir    = "/usr/apps/walnut/current"

if File.exists?(walnut_dir)
  # production environment
  RAILS_ROOT  = walnut_dir
  rails_env   = 'production'
else
  # assume development environment, use current directory
  RAILS_ROOT  = File.dirname(File.dirname(__FILE__))
  rails_env   = 'development'
end

# Load user, group info
config  = YAML.load_file("#{RAILS_ROOT}/config/god/user.yml")
user    = config['user']
group   = config['group']

# Create, set permissions on default pid file directory
system "mkdir -p /var/run/god"
system "chmod ugo+rw /var/run/god"

God.pid_file_directory = '/var/run/god'  # default value

def generic_monitoring(w, options = {})
  w.start_if do |start|
    start.condition(:process_running) do |c|
      c.interval = 10.seconds
      c.running = false
    end
  end
  
  w.restart_if do |restart|
    restart.condition(:memory_usage) do |c|
      c.above = options[:memory_limit]
      c.times = [3, 5] # 3 out of 5 intervals
    end
  
    restart.condition(:cpu_usage) do |c|
      c.above = options[:cpu_limit]
      c.times = 5
    end
  end
  
  w.lifecycle do |on|
    on.condition(:flapping) do |c|
      c.to_state      = [:start, :restart]
      c.times         = 5
      c.within        = 5.minute
      c.transition    = :unmonitored
      c.retry_in      = 10.minutes
      c.retry_times   = 5
      c.retry_within  = 2.hours
    end
  end
end

# memcached
# pid file  => /var/run/god
# no log files
# port 11211
God.watch do |w|
  pid_file          = "#{God.pid_file_directory}/memcached.pid"
  w.name            = "memcached"
  w.uid             = user
  w.gid             = group
  w.interval        = 60.seconds
  w.start           = "memcached -d -p 11211 -P #{pid_file} -m 256"
  w.stop            = "kill `cat #{pid_file}`"
  w.start_grace     = 10.seconds
  w.restart_grace   = 10.seconds
  w.pid_file        = pid_file
  
  w.behavior(:clean_pid_file)
  
  generic_monitoring(w, :cpu_limit => 30.percent, :memory_limit => 20.megabytes)
end

# nginx
# log, pid files => /usr/local/nginx/logs
God.watch do |w|
  script            = "/etc/init.d/nginx"
  w.name            = "nginx"
  w.interval        = 60.seconds
  w.start           = "#{script} start"
  w.stop            = "#{script} stop"
  w.restart         = "#{script} restart"
  w.start_grace     = 20.seconds
  w.restart_grace   = 20.seconds
  w.pid_file        = "/usr/local/nginx/logs/nginx.pid"

  w.behavior(:clean_pid_file)

  # determine the state on startup
  w.transition(:init, { true => :up, false => :start }) do |on|
    on.condition(:process_running) do |c|
      c.running = true
    end
  end

  # determine when process has finished starting
  w.transition([:start, :restart], :up) do |on|
    on.condition(:process_running) do |c|
      c.running = true
    end
    # failsafe
    on.condition(:tries) do |c|
      c.times = 8
      c.within = 2.minutes
      c.transition = :start
    end
  end

  start if process is not running
  w.transition(:up, :start) do |on|
    on.condition(:process_exits)
  end

  w.transition(:up, :restart) do |on|
    on.condition(:http_response_code) do |c|
      c.host = 'localhost'
      c.port = 5000
      c.path = '/monitor.html'
      c.code_is_not = 200
      c.timeout = 10.seconds
      c.times = [3, 5]
    end
  end

  generic_monitoring(w, :cpu_limit => 50.percent, :memory_limit => 50.megabytes)
end

# MySQL monitoring
God.watch do |w|
  script            = "/etc/init.d/mysql"
  w.name            = 'mysql'
  w.interval        = 30.seconds # default
  w.start           = "#{script} start"
  w.stop            = "#{script} stop"
  w.restart         = "#{script} restart"
  w.start_grace     = 10.seconds
  w.restart_grace   = 10.seconds
  w.pid_file        = '/var/run/mysqld/mysqld.pid'
  w.behavior(:clean_pid_file)

  w.start_if do |start|
    start.condition(:process_running) do |c|
      c.interval = 5.seconds
      c.running = false
    end
  end

  # lifecycle
  w.lifecycle do |on|
    on.condition(:flapping) do |c|
      c.to_state = [:start, :restart]
      c.times = 5
      c.within = 5.minute
      c.transition = :unmonitored
      c.retry_in = 10.minutes
      c.retry_times = 5
      c.retry_within = 2.hours
    end
  end
end

# log, pid files => RAILS_ROOT/log
# God.watch do |w|
#   script            = "#{RAILS_ROOT}/script/workling_client"
#   w.name            = "workling"
#   w.uid             = user
#   w.gid             = group
#   w.interval        = 60.seconds
#   w.start           = "#{script} start"
#   w.restart         = "#{script} restart"
#   w.stop            = "#{script} stop"
#   w.start_grace     = 20.seconds
#   w.restart_grace   = 20.seconds
#   w.pid_file        = "#{RAILS_ROOT}/log/workling.pid"
#   
#   w.behavior(:clean_pid_file)
#   
#   generic_monitoring(w, :cpu_limit => 80.percent, :memory_limit => 100.megabytes)
# end
# 
# # pid file  => /var/run/god
# # log files => ?
# God.watch do |w|
#   pid_file          = "#{God.pid_file_directory}/starling.pid"
#   w.name            = "starling"
#   w.uid             = user
#   w.gid             = group
#   w.interval        = 60.seconds
#   w.start           = "starling -d -p 22122 -P #{pid_file} -q #{RAILS_ROOT}/log/"
#   w.stop            = "kill `cat #{pid_file}`"
#   w.start_grace     = 10.seconds
#   w.restart_grace   = 10.seconds
#   w.pid_file        = pid_file
#   
#   w.behavior(:clean_pid_file)
#   
#   generic_monitoring(w, :cpu_limit => 30.percent, :memory_limit => 20.megabytes)
# end


# pid file => /var/run
# God.watch do |w|
#   w.name            = "apache"
#   w.interval        = 30.seconds # default
#   w.start           = "#{apache} start"
#   w.stop            = "#{apache} stop"
#   w.restart         = "#{apache} restart"
#   w.start_grace     = 10.seconds
#   w.restart_grace   = 10.seconds
#   w.pid_file        = "/var/run/httpd.pid"
# 
#   w.behavior(:clean_pid_file)
# 
#   generic_monitoring(w, :cpu_limit => 30.percent, :memory_limit => 100.megabytes)
# end
  
# run these in production environments
# if rails_env == 'production'
  
  # log, pid files => RAILS_ROOT/log
  # %w{5000 5001}.each do |port|
  #   God.watch do |w|
  #     w.name          = "mongrel-#{port}"
  #     w.group         = "mongrels"
  #     w.uid           = user
  #     w.gid           = group
  #     w.interval      = 60.seconds      
  #     w.start         = "mongrel_rails start -c #{RAILS_ROOT} -p #{port} -e #{rails_env} \
  #                       -P #{RAILS_ROOT}/log/mongrel.#{port}.pid  -d"
  #     w.stop          = "mongrel_rails stop -P #{RAILS_ROOT}/log/mongrel.#{port}.pid"
  #     w.restart       = "mongrel_rails restart -P #{RAILS_ROOT}/log/mongrel.#{port}.pid"
  #     w.start_grace   = 10.seconds
  #     w.restart_grace = 10.seconds
  #     w.pid_file      = "#{RAILS_ROOT}/log/mongrel.#{port}.pid"
  #   
  #     w.behavior(:clean_pid_file)
  # 
  #     generic_monitoring(w, :cpu_limit => 50.percent, :memory_limit => 150.megabytes)
  #   end
  # end
  # 

# end # production environment


