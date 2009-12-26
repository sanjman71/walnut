class MessageComposeInvitation

  def self.provider(invitation, invite_url)
    company   = invitation.company
    sender    = MessageCompose.sender(company)

    # send invitation
    subject   = "[#{company.name}] Invitation"
    body      = "#{invitation.sender.name.to_s.titleize} has invited you to sign up as a company provider.  Your invitation url is #{invite_url}."
    email     = invitation
    message   = MessageCompose.send(sender, subject, body, [email], invitation, 'provider')

    return message
  end

end