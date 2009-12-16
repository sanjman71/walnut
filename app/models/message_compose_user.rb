class MessageComposeUser

  # send user created
  def self.created(user)
    return -1 if user.blank?
    return -1 if user.email_addresses_count == 0

    email     = user.primary_email_address
    subject   = "[#{user.name}] Account created" 
    body      = "Your user account was created"
    sender    = MessageCompose.sender(user) # default sender
    message   = MessageCompose.send(sender, subject, body, [email], user, 'created')

    return 0
  end
  
  # send user password reset
  def self.password_reset(user, password)
    return -1 if user.blank?
    return -1 if user.email_addresses_count == 0

    email     = user.primary_email_address
    subject   = "[#{user.name}] Password reset" 
    body      = "Your new password is: #{password}"
    sender    = MessageCompose.sender(user) # default sender
    message   = MessageCompose.send(sender, subject, body, [email], user, 'reset')

    return 0
  end

end