# Copyright (c) 2006 Stuart Eccles
# Released under the MIT License.  See the LICENSE file for more details.

require 'mime/types'
class CalDavResource
  include WebDavResource

  attr_accessor :href, :appointments, :company
  
  WEBDAV_PROPERTIES = [:displayname, :creationdate, :getlastmodified, :getcontenttype, :getcontentlength]

  def initialize(appointments, company)
    @appointments = appointments
    @company = company
  end

  def properties
    debugger
    WEBDAV_PROPERTIES
  end 

  def displayname 
    return "Calendar for #{@company.name}.ics" unless @appointments.nil?
  end
  
  def creationdate
    if !@company.nil? and @company.respond_to? :created_at
      @company.created_at.httpdate
    end
  end
  
  def getlastmodified
    if !@company.nil? and @company.respond_to? :updated_at
      @company.updated_at.httpdate
    end
  end
  
  def getcontenttype
    debugger
    MIME::Types['text/calendar']
  end

  def getcontentlength 
    0
  end

  def data
    raise NotFoundError unless @appointments
    
    cal = RiCal.Calendar do |cal|
      @appointments.each do |app|
        cal.event do |ev|
          ev.add_attendee "#{app.provider.email}"
          # No customer if this is available time
          if app.service.mark_as == "free"
            ev.summary "#{app.provider.name}: Available"
          else
            ev.summary "#{app.provider.name}: #{app.service.name} for #{app.customer.name}"
            ev.add_attendee "#{app.customer.email}"
          end
          ev.dtstart     app.start_at
          ev.dtend       app.end_at
          if app.location
            ev.location    "#{app.location.name}"
          end
          ev.description = app.description
          app.notes.each do |n|
            ev.add_comment n
          end
        end
      end  
    end
    cal.export
  end
end
