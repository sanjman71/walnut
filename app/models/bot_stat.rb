class BotStat < ActiveRecord::Base
  validates_presence_of   :name, :date, :count
  validates_uniqueness_of :date, :scope => :name
  
  named_scope   :googlebot, :conditions => ["name = 'googlebot'"]
  named_scope   :googlemedia, :conditions => ["name = 'googlemedia'"]
  
  named_scope   :order_by_most_recent, :order => "date DESC"
  
  def self.create_or_update(name, date, count)
    stat = self.send(name.to_sym).find_by_date(date)
    
    if stat.blank?
      # create
      stat = self.create(:name => name, :date => date, :count => count)
    elsif stat.count != count
      # update count
      stat.count = count
      stat.save
    end
  end
end