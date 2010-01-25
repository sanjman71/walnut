ActionMailer::Base.smtp_settings = {
  :tls => true,
  :address => "smtp.gmail.com",
  :port => "587",
  :authentication => :plain,
  :user_name => "messaging@walnutindustries.com",
  :password => "1ndus7ry!"
}
