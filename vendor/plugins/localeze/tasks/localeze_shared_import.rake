require "#{RAILS_ROOT}/config/environment"
require 'fastercsv'
require 'ar-extensions'

namespace :localeze do
  namespace :shared do
    
    LOCALEZE_DATA_DIR = "#{RAILS_ROOT}/vendor/plugins/localeze/data"
    
    # Task Import:
    #  - works fine
    desc "Import localeze categories"
    task :import_categories do
      klass     = Localeze::Category
      columns   = [:id, :name]
      file      = "#{LOCALEZE_DATA_DIR}/categories.txt"
      options   = { :validate => false }
    
      # truncate table
      klass.delete_all

      puts "#{Time.now}: importing file #{file}, starting with #{klass.count} objects" 
      FasterCSV.foreach(file, :row_sep => "\r\n", :col_sep => '|') do |row|
        klass.import columns, [row], options
      end

      puts "#{Time.now}: completed, ended with #{klass.count} objects" 
    end

    # Task Import:
    #  * failed with 'illegal quote' error
    desc "Import localeze chains"
    task :import_chains do
      klass     = Localeze::Chain
      columns   = [:id, :name]
      file      = "#{LOCALEZE_DATA_DIR}/chains.txt"
      options   = { :validate => false }
    
      # truncate table
      klass.delete_all

      puts "#{Time.now}: importing file #{file}, starting with #{klass.count} objects" 
      FasterCSV.foreach(file, :row_sep => "\r\n", :col_sep => '|') do |row|
        klass.import columns, [row], options
      end

      puts "#{Time.now}: completed, ended with #{klass.count} objects" 
    end
    
  end # shared
end # localeze