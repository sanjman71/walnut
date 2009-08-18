namespace :ts do

  namespace :start do
    desc "Start Sphinx searchd daemon using Thinking Sphinx's settings with iostats"
    task :iostats do
      config = ThinkingSphinx::Configuration.instance

      FileUtils.mkdir_p config.searchd_file_path
      raise RuntimeError, "searchd is already running." if sphinx_running?

      Dir["#{config.searchd_file_path}/*.spl"].each { |file| File.delete(file) }

      cmd = "#{config.bin_path}searchd --pidfile --config #{config.config_file} --iostats"
      puts cmd
      system cmd

      sleep(2)

      if sphinx_running?
        puts "Started successfully (pid #{sphinx_pid})."
      else
        puts "Failed to start searchd daemon. Check #{config.searchd_log_file}."
      end
    end
  end

  namespace :index do

    desc "Index appointments data for Sphinx using Thinking Sphinx's settings"
    task :appointments do
      ThinkingSphinx::Deltas::Job.cancel_thinking_sphinx_jobs

      config = ThinkingSphinx::Configuration.instance
      FileUtils.mkdir_p config.searchd_file_path
      cmd = "#{config.bin_path}indexer --config #{config.config_file} appointment_core"
      cmd << " --rotate" if sphinx_running?
      puts cmd
      system cmd
    end

    desc "Index appointments data for Sphinx using Thinking Sphinx's settings"
    task :appts => "ts:index:appointments"

    desc "Index locations data for Sphinx using Thinking Sphinx's settings"
    task :locations do
      ThinkingSphinx::Deltas::Job.cancel_thinking_sphinx_jobs
    
      config = ThinkingSphinx::Configuration.instance
      FileUtils.mkdir_p config.searchd_file_path
      cmd = "#{config.bin_path}indexer --config #{config.config_file} location_core"
      cmd << " --rotate" if sphinx_running?
      puts cmd
      system cmd
    end
  end
end