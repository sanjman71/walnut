namespace :ts do
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