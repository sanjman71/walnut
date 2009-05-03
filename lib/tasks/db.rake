namespace :db do
  
  
  desc "Backup the database to the /backups directory"
  task :backup do
    mysqldump           = 'mysqldump'
    mysqldump_options   = '--single-transaction --quick'
    username            = ActiveRecord::Base.configurations[RAILS_ENV]['username']
    password            = ActiveRecord::Base.configurations[RAILS_ENV]['password']
    host                = ActiveRecord::Base.configurations[RAILS_ENV]['host']
    database_name       = ActiveRecord::Base.configurations[RAILS_ENV]['database']
    
    timestamp           = Time.now.strftime("%Y%m%d%H%M%S")
    backup_dir          = "#{RAILS_ROOT}/backups"
    backup_file         = "#{database_name}_#{timestamp}.sql.gz"
    
    cmd = "#{mysqldump} #{mysqldump_options} -u#{username} -p#{password} -h#{host} #{database_name} | gzip -c > #{backup_dir}/#{backup_file}"
    
    puts "#{Time.now}: creating backup in backups/#{backup_file}"
    system cmd
    puts "#{Time.now}: created backup"
    
    dir         = Dir.new(backup_dir)
    max_backups = ENV["MAX"] ? ENV["MAX"].to_i : 5
    all_backups = dir.entries[2..-1].sort.reverse

    unwanted_backups = all_backups[max_backups..-1] || []
    for unwanted_backup in unwanted_backups
      FileUtils.rm_rf(File.join(backup_dir, unwanted_backup))
      puts "#{Time.now}: deleted #{unwanted_backup}" 
    end

    puts "#{Time.now}: deleted #{unwanted_backups.length} backups, #{all_backups.length - unwanted_backups.length} backups available" 
  end

  desc "Restore the database from the specified sql dump file"
  task :restore do
    if ENV["FILE"].blank?
      puts "no FILE specified"
      exit
    end

    load_file = ENV["FILE"]

    if !File.exists?(load_file)
      puts "file #{load_file} does not exist"
      exit
    end
    
    mysqlload           = 'mysql'
    username            = ActiveRecord::Base.configurations[RAILS_ENV]['username']
    password            = ActiveRecord::Base.configurations[RAILS_ENV]['password']
    host                = ActiveRecord::Base.configurations[RAILS_ENV]['host']
    database_name       = ActiveRecord::Base.configurations[RAILS_ENV]['database']
    
    if load_file.match(/.gz$/)
      # unzip, then reset load file name
      cmd = "gunzip #{load_file}"
      puts "#{Time.now}: unzipping #{load_file}"
      system cmd
      load_file = load_file.gsub(".gz", '')
    end
    
    cmd = "#{mysqlload} -u#{username} -p#{password} -h#{host} #{database_name} < #{load_file}"
    puts "#{Time.now}: loading file '#{load_file}' into database '#{database_name}'"
    system cmd
    puts "#{Time.now}: completed"
  end
end
