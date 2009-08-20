# Use this file to easily define all of your cron jobs.
#
# It's helpful, but not entirely necessary to understand cron before proceeding.
# http://en.wikipedia.org/wiki/Cron

# Example:
#
# set :cron_log, "/path/to/my/cron_log.log"
#
# every 2.hours do
#   command "/usr/bin/some_great_command"
#   runner "MyModel.some_method"
#   rake "some:great:rake:task"
# end
#
# every 4.days do
#   runner "AnotherModel.prune_old_records"
# end

# Learn more: http://github.com/javan/whenever

if RAILS_ENV == 'development'

every 1.day, :at => "2am" do
  command "curl http://www.walnutplaces.dev:3000/sphinx?token=#{AUTH_TOKEN_INSTANCE} > /dev/null"
end

end # development

if RAILS_ENV == 'production'

every 1.day, :at => "2am" do
  command "curl http://www.walnutplaces.com/events/remove?token=#{AUTH_TOKEN_INSTANCE} > /dev/null"
  command "curl http://www.walnutplaces.com/events/import?token=#{AUTH_TOKEN_INSTANCE} > /dev/null"
end

every :reboot do
  command "cd /usr/apps/walnut/current && RAILS_ENV=production /usr/bin/env rake ts:start"
end

end # production