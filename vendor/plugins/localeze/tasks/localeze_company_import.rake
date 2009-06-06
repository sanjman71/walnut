require "#{RAILS_ROOT}/config/environment"
require 'fastercsv'
require 'ar-extensions'

namespace :localeze do
  namespace :company do
    
    LOCALEZE_COMPANY_DATA_DIR = "/Users/sanjay/Desktop/EnhancedBuild_200903"

    # 167874 958235|||FLOWERS FOR ANY EVENT|Flowers for Any Event||55191||Shelby|Rd|||||Shelby Township|MI|48316|1150|911|C014|26|099|S|2
    # 167874 25401|0|16|2160|||||8|G|Y|248|652|1742||1|7|C|||54|R|42.699037|-83.069886|1980|||We Create The Look You Want For "Any Event"
    # 167874  In Your Life|||||||||||||
  
    # Task Import:
    #   - import ~ 127951 Chicago base records took ~5 minutes
    #   - import ~ 437274 CBSA 16980 (Chicagoland) base records took ~5 minutes
    desc "Clean base records txt file, either with CITY or CBSA"
    task :clean_base_records do
      # check for filters
      city    = ENV["CITY"] ? ENV["CITY"].titleize : nil
      cbsa    = ENV["CBSA"] ? ENV["CBSA"].to_s.strip : nil
      
      if city.blank? and cbsa.blank?
        puts "usage error: missing CITY or CBSA"
        exit
      end
      
      input   = "#{LOCALEZE_COMPANY_DATA_DIR}/BaseRecords.txt"
      output  = "#{LOCALEZE_COMPANY_DATA_DIR}/BaseRecords.csv"
      cleaned = 0
      wrote   = 0
    
      puts "#{Time.now}: cleaning file #{input} and writing to #{output}"
    
      File.open(output, "w") do |fwrite|
        File.open(input, "r") do |fread|
          while s = fread.gets
      
            if city
              next unless s.match(/\|#{city}\|/)
            end

            if cbsa
              next unless s.match(/\|#{cbsa}\|/)
            end
        
            if s.match(/"/)
              # remove quotes
              puts "#{Time.now}: *** matched: #{s}"
              s = s.gsub(/"/,'')
              cleaned += 1
            end
          
            # write to output file
            fwrite.puts(s)
            wrote += 1
          end # while fread
        end # File.open read
      end # File.open write
    
      puts "#{Time.now}: completed, cleaned #{cleaned} records, wrote #{wrote} records"
    end
  
    # Navicat Import:
    #  - import ~437K records in ~3 minutes
    #  - import 15725783 records in 14343 seconds
    #  - .txt import
    # Task Import: 
    #  - import 10K records in ~1 minute
    #  - import 121K records in ~12 minutes
    desc "Import base records"
    task :import_base_records do
      klass     = Localeze::BaseRecord
      columns   = [:id, :chain_id, :pubdate, :businessname, :stdname, :subdepartment, :housenumber, :predirectional, :streetname, :streettype,
                   :postdirectional, :apttype, :aptnumber, :exppubcity, :city, :state, :zip, :plus4, :dpc, :carrierroute, :statefips,
                   :countyfips, :z4type, :censustract, :censusblockgroup, :censusblockid, :msa, :cbsa, :mcd, :addresssensitivity, 
                   :genrc, :mlsc, :goldflag, :dpvconfirm, :areacode, :exchange, :phonenumber, :dnc, :dso, :timezone, :valflag, :valdate,
                   :valflag2, :filler44, :llmatchlevel, :latitude, :longitude, :firstyear, :stdhours, :hoursopen, :tagline, 
                   :filler53, :filler54, :filler55, :filler56, :filler57, :filler58, :filler59, :filler60, :filler61, :filler62, :filler63,
                   :filler64, :filler65
                  ]
      file      = "#{LOCALEZE_COMPANY_DATA_DIR}/BaseRecords.csv"
      options   = { :validate => false }
      limit     = ENV["LIMIT"] ? ENV["LIMIT"].to_i : 2**30
      city      = ENV["CITY"] ? ENV["CITY"].titleize : nil
      cbsa      = ENV["CBSA"] ? ENV["CBSA"].to_s.strip : nil
      imported  = 0
    
      puts "#{Time.now}: importing file #{file}, city: #{city}, cbsa: #{cbsa}, limit: #{limit}, starting with #{klass.count} objects"

      FasterCSV.foreach(file, :row_sep => "\r\n", :col_sep => '|') do |row|
        # filter by city or cbsa
        next if city and row[14] != city
        next if cbsa and row[27] != cbsa
        
        # skip if record exists
        next if klass.exists?(:id => row[0])
      
        klass.import columns, [row], options 
        imported += 1
      
        break if imported >= limit
      end

      puts "#{Time.now}: completed, ended with #{klass.count} objects" 
    end
  
    def find_all_base_record_ids
      Localeze::BaseRecord.find(:all, :select => ["id"]).collect(&:id)
    end

    # Navicat Import:
    #  - ~18M records in 11 minutes
    #  - ~18M records in 20 minutes
    # Task Import: 
    #  - import ~11750000 records in 507 minutes
    desc "Import company headings"
    task :import_company_headings do
      klass     = Localeze::CompanyHeading
      columns   = [:id, :base_record_id, :normalized_detail_id, :condensed_detail_id, :category_id, :relevancy]
      file      = "#{LOCALEZE_COMPANY_DATA_DIR}/CompanyHeadings.txt"
      options   = { :validate => false }
      id        = 1
  
      # truncate table
      klass.delete_all
    
      puts "#{Time.now}: importing file #{file}, starting with #{klass.count} objects" 
      FasterCSV.foreach(file, :row_sep => "\r\n", :col_sep => '|') do |row|
        base_record_id, normalized_detail_id, condensed_detail_id, category_id, relevancy = row
      
        value = [id] + row
        klass.import columns, [value], options
        id += 1
      
        puts "#{Time.now}: *** added #{id} records" if (id % 10000) == 0
      end

      puts "#{Time.now}: completed, ended with #{klass.count} objects" 
    end
  
    # Navicat Import:  
    #  - ~12.5M records in 15 minutes
    #  - ~12.5M records in 50 minutes
    # Task Import: 
    #  - ~5000000 records in 236 minutes
    desc "Import company (structured) attributes"
    task :import_company_attributes do
      klass     = Localeze::CompanyAttribute
      columns   = [:id, :base_record_id, :name, :group_name, :group_type, :category_id]
      file      = "#{LOCALEZE_COMPANY_DATA_DIR}/CompanyAttributes.txt"
      options   = { :validate => false } 
      id        = 1
    
      # truncate table
      klass.delete_all
    
      puts "#{Time.now}: importing file #{file}, starting with #{klass.count} objects" 
      FasterCSV.foreach(file, :row_sep => "\r\n", :col_sep => '|') do |row|
        base_record_id, xxx, name, group_name, group_type, category_id = row
      
        value = [id, base_record_id, name, group_name, group_type, category_id]
        klass.import columns, [value], options
        id += 1

        puts "#{Time.now}: *** added #{id} records" if (id % 10000) == 0
      end

      puts "#{Time.now}: completed, ended with #{klass.count} objects" 
    end

    # Performance: ?
    # desc "Import company unstructured attributes"
    # task :import_unstructured_attributes do
    #   klass   = CompanyUnstructuredAttribute
    #   columns = [:id, :base_record_id, :name, :relevancy]
    #   file    = "#{RAILS_ROOT}/company_unstructured_attributes.txt"
    #   values  = []
    #   options = { :validate => false } 
    #   id      = 1
    #   base_ids  = find_all_base_record_ids
    #   
    #   # truncate table
    #   klass.delete_all
    #   
    #   puts "#{Time.now}: importing file #{file}, starting with #{klass.count} objects" 
    #   FasterCSV.foreach(file, :row_sep => "\r\n", :col_sep => '|') do |row|
    #     base_record_id, name, relevancy = row
    #     
    #     # check that the associated base record exists
    #     next unless base_ids.include?(base_record_id.to_i)
    #     
    #     value = [id, base_record_id, name, relevancy]
    #     values << value
    #     id += 1
    #   end
    # 
    #   puts "#{Time.now}: completed, ended with #{klass.count} objects" 
    # end

    desc "Import company custom attributes"
    task :import_custom_attributes do
      klass     = CustomAttribute
      columns   = [:id, :base_record_id, :name, :custom_attribute_type_id, :description, :relevancy]
      file      = "#{LOCALEZE_COMPANY_DATA_DIR}/CustomAttributes.txt"
      options   = { :validate => false } 
      id        = 1
      base_ids  = find_all_base_record_ids
    
      # truncate table
      klass.delete_all
    
      puts "#{Time.now}: importing file #{file}, limit: #{limit}, starting with #{klass.count} objects" 
      FasterCSV.foreach(file, :row_sep => "\r\n", :col_sep => '|') do |row|
        base_record_id, name, custom_attribute_type_id, description, relevancy = row
      
        # check that the associated base record exists
        next unless base_ids.include?(base_record_id.to_i)

        value = [id] + row
        klass.import columns, [value], options
        id += 1
      end
    
      puts "#{Time.now}: completed, ended with #{klass.count} objects" 
    end

    desc "Import company payment types"
    task :import_company_payment_types do
      klass     = CompanyPaymentType
      columns   = [:id, :base_record_id, :name]
      file      = "#{LOCALEZE_COMPANY_DATA_DIR}/CompanyPaymentTypes.txt"
      options   = { :validate => false } 
      id        = 1
    
      # truncate table
      klass.delete_all
    
      puts "#{Time.now}: importing file #{file}, limit: #{limit}, starting with #{klass.count} objects" 
      FasterCSV.foreach(file, :row_sep => "\r\n", :col_sep => '|') do |row|
        base_record_id, payment_type_id = row
        # map payment type id to a payment type
        value = [id, base_record_id, map_payment_type_id(payment_type_id)]
        klass.import columns, [value], options
        id += 1
      end
    
      puts "#{Time.now}: completed, ended with #{klass.count} objects" 
    end

    # Performance: ?
    desc "Import company phones"
    task :import_company_phones do
      klass   = Localeze::CompanyPhone
      columns = [:id, :base_record_id, :areacode, :exchange, :phonenumber, :phonetype, :valflag, :valdate, :dnc]
      file    = "#{LOCALEZE_COMPANY_DATA_DIR}/CompanyPhones.txt"
      options = { :validate => false } 
      id      = 1
  
      # truncate table
      klass.delete_all

      puts "#{Time.now}: parsing file #{file}" 
      FasterCSV.foreach(file, :row_sep => "\r\n", :col_sep => '|') do |row|
        base_record_id, areacode, exchange, phonenumber, phonetype, valflag, valdate, dnc = row
      
        value = [id] + row
        klass.import columns, [value], options
        id += 1
      
        puts "#{Time.now}: *** added #{id} records" if (id % 1000) == 0
      end
    
      puts "#{Time.now}: completed, ended with #{klass.count} objects" 
    end
  
    # map payment id to a payment name
    def map_payment_type_id(id)
      case id.to_i
      when 1
        'Cash'
      when 2
        'Check'
      when 3
        'Visa'
      when 4
        'MasterCard'
      when 5
        'Discover'
      when 6
        'Americann Express'
      when 7
        'Diners'
      when 8
        'Debit'
      else
        nil
      end
    end
    
  end # company namespace
end # localeze namespace
