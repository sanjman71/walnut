class UserMailer < ActionMailer::Base
  
  def account_created(company, user, creator, password, login_url)
    from("peanut@jarna.com")
    recipients(user.email)
    subject("#{company.name}: Your user account was created")
    body(:user => user, :creator => creator, :password => password, :login_url => login_url)
  end
  
  def account_reset(company, user, password, login_url)
    from("peanut@jarna.com")
    recipients(user.email)
    subject("#{company.name}: Your account password has been reset")
    body(:user => user, :password => password, :login_url => login_url)
  end
  
  def message(company, user, message)
    from("peanut@jarna.com")
    recipients(user.email)
    subject("#{company.name}: message")
    body(:message => message)
  end
  
end
