class InvitationNotifier < ActionMailer::Base

  def invitation(invitation, signup_url)
    from("peanut@jarna.com")
    recipients(invitation.recipient_email)
    subject("#{invitation.company.name}: Invitation")
    body(:invitation => invitation, :sender => invitation.sender, :signup_url => signup_url)
  end

end