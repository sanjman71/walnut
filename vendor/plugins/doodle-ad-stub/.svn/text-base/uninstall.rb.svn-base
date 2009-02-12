require 'fileutils'

source = File.dirname(__FILE__)
target = defined?(RAILS_ROOT) ? RAILS_ROOT : "#{source}/../../.."

def remove_file_if_exists(name)
  shortname = File.basename(name)
  return puts("! skipped #{shortname}, not found!") unless File.exists?(name)
  FileUtils.rm(name)
  puts "- deleted #{shortname}"
end

def remove_directory_if_exists_and_empty(name)
  shortname = File.basename(name)
  return puts("! skipped #{shortname}, not found") unless File.exists?(name)
  return puts("! skipped #{shortname}, is not a directory") unless File.directory?(name)
  return puts("! skipped #{shortname}, is not empty") unless (Dir.entries(name) - ['.', '..']).empty?
  FileUtils.rm_r(name)
  puts "- deleted #{shortname}"
end

puts "Removing Doodle AdStub Helper..."

# removing images
images_bundled_dir   = "#{source}/public/images/doodle_ad_stub"
images_installed_dir = "#{target}/public/images/doodle_ad_stub"
Dir.foreach(images_bundled_dir) do |image|
  remove_file_if_exists(File.join(images_installed_dir, File.basename(image))) unless image.match('^\.')
end
remove_directory_if_exists_and_empty(images_installed_dir) 

# removing config
remove_file_if_exists("#{target}/config/initializers/doodle_ad_stub.rb")

puts "Plugin has been removed. Bye..."
