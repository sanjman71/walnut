class MessagesController < ApplicationController

  def index
    respond_to do |format|
      format.html
    end
  end
  
  def new_email
    @email_collection   = EmailAddress.with_emailable_type('User').all(:include => :emailable).collect { |o| [o.emailable, o] }
    @recipient_type     = EmailAddress.to_s
    @protocol           = 'email'

    respond_to do |format|
      format.html
    end
  end

  def new_sms
    @phone_collection   = PhoneNumber.with_callable_type('User').all(:include => :callable).collect { |o| [o.callable, o] }
    @recipient_type     = PhoneNumber.to_s
    @protocol           = 'sms'

    respond_to do |format|
      format.html
    end
  end

  def create
    begin
      # find recipient
      @recipient  = Kernel.const_get(params[:recipient_type]).find(params[:recipient_id])
    rescue Exception => e
      flash[:error] = "Invalid recipient"
      redirect_to(request.referer) and return
    end

    # build message
    @protocol = params[:protocol]
    @options  = params[:message].merge(:sender => current_user)
    
    # create message and recipients
    @message  = Message.create(@options)
    
    if !@message.valid?
      flash[:error] = @message.errors.full_messages
      redirect_to(request.referer) and return
    end
    
    Array[@recipient].each do |recipient|
      @message.message_recipients.create(:messagable => recipient, :protocol => @protocol)
    end

    # send the message
    @message.send!

    flash[:notice] = "Sent message"
    
    redirect_to(messages_path) and return
  end
end