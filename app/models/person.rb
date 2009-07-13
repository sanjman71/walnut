class Person < ActiveRecord::Base
  validates_presence_of     :name
  
  # search on the name field
  named_scope               :search_name,         lambda { |s| { :conditions => ["LOWER(name) REGEXP '%s'", s.downcase] }}
  
  # find people who provide at least 1 service
  named_scope               :provide_services,    {:conditions => ["services_count > 0"]}

  # find people who provide no services
  named_scope               :no_services,         {:conditions => ["services_count = 0"]}
  
  # the special anyone person
  def self.anyone
    r = Person.new do |o|
      o.name = "Anyone"
      o.send(:id=, 0)
    end
  end
  
  # return true if its the special person 'anyone'
  def anyone?
    self.id == 0
  end
  
end