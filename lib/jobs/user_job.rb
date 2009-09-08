class UserJob < BaseJob
  def logger
    case RAILS_ENV
    when 'development'
      @logger ||= Logger.new(STDOUT)
    else
      @logger ||= Logger.new("log/users.log")
    end
  end

  def perform
    logger.info "#{Time.now}: [ok] user job: #{params.inspect}"

    begin
      user = User.find(params[:id])
    rescue
      logger.error "#{Time.now}: [error] invalid user #{params[:id]}"
      return
    end
    
    begin
      case params[:method]
      when 'send_account_created'
        send_account_created(user, params[:password])
      when 'send_password_reset'
        send_password_reset(user, params[:password])
      else
        logger.error "#{Time.now}: [error] ignoring method #{params[:method]}"
      end
    rescue Exception => e
      logger.info "#{Time.now}: [error] #{e.message}, #{e.backtrace}"
    end
  end
  
  def send_account_created(user, password)
    email     = user.primary_email_address
    company   = user.appointments.size > 0 ? user.appointments.first.company : nil
    
    protocol  = 'email'
    address   = email.address
    subject   = "[#{company ? company.name : user.name}] account created" 
    body      = "Your user account was created with the following password: #{password}"

    send_message_using_message_pub(subject, body, protocol, address)
  end

  def send_password_reset(user, password)
    email     = user.primary_email_address
    
    protocol  = 'email'
    address   = email.address
    subject   = "[#{user.name}] password reset" 
    body      = "Your new password is: #{password}"

    send_message_using_message_pub(subject, body, protocol, address)
  end

end