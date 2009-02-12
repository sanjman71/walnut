require 'fileutils'

source = File.dirname(__FILE__)
target = defined?(RAILS_ROOT) ? RAILS_ROOT : "#{source}/../../.."

def copy_file_if_not_exists(from_name, to_name)
  shortname = File.basename(to_name)
  return puts("! skipped file #{shortname}, already exists!") if File.exists?(to_name)
  FileUtils.cp(from_name, to_name)
  puts "+ copied file #{shortname}"
end

def make_directory_if_not_exists(name)
  shortname = File.basename(name)
  return puts("! skipped directory #{shortname}, already exists!") if File.directory?(name)
  FileUtils.mkdir(name)
  puts "+ created directory #{shortname}"
end

puts "Installing Doodle AdStub Helper..."

# installing images
images_source_dir = "#{source}/public/images/doodle_ad_stub"
images_target_dir = "#{target}/public/images/doodle_ad_stub"
make_directory_if_not_exists(images_target_dir)
Dir.foreach(images_source_dir) do |image|
  copy_file_if_not_exists(File.join(images_source_dir, File.basename(image)),
                          File.join(images_target_dir, File.basename(image))) unless image.match('^\.')
end

# installing config
copy_file_if_not_exists(File.join(source, "/public/doodle_ad_stub.rb"),
                        File.join(target, "/config/initializers/ppds_doodle_ad_stub.rb"))

puts "Congrats, plugin has been installed."

#puts IO.read("#{source}/README")
