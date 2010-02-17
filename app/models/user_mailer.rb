class UserMailer < ActionMailer::Base

  def account_created(company, user, creator, password, login_url)
    from(SMTP_FROM)
    recipients(user.email)
    subject("#{company.name}: Your user account was created")
    body(:user => user, :creator => creator, :password => password, :login_url => login_url)
  end

  def account_reset(company, user, password, login_url)
    from(SMTP_FROM)
    recipients(user.email)
    subject("#{company.name}: Your account password has been reset")
    body(:user => user, :password => password, :login_url => login_url)
  end

  def message(company, user, message)
    from(SMTP_FROM)
    recipients(user.email)
    subject("#{company.name}: message")
    body(:message => message)
  end

  def email(to, subject, body, options={})
    from(SMTP_FROM)
    recipients(to)
    subject(subject)

    if options[:template].blank?
      # use default template
      options[:body] = body
      template_html  = "email.html.haml"
      template_text  = "email.text.haml"
    else
      # use specified template to render email body
      template_html = options[:template].to_s + ".html.haml"
      template_text = options[:template].to_s + ".text.haml"
    end

    part :content_type => "multipart/alternative" do |a|
      a.part "text/plain" do |p|
        p.body = render_message(template_text, options)
      end

      unless options.empty?
        a.part "text/html" do |p|
          p.body = render_message(template_html, options)
        end
      end
    end

  end

end
