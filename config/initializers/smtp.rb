ActionMailer::Base.smtp_settings = {
  :tls => true,
  :address => "smtp.gmail.com",
  :port => "587",
  :authentication => :plain,
  :user_name => "walnut@jarna.com",
  :password => "walnut!" 
}
