class MessageComposeInvitation

  def self.staff(invitation, invite_url)
    company   = invitation.company
    sender    = MessageCompose.sender(company)

    # build message options
    options   = Hash[:template => :invitation, :topic => invitation, :tag => 'staff', :company_name => company.name, 
                     :sender_name => invitation.sender.name.to_s.titleize, :invite_url => invite_url]

    # send invitation
    subject   = "[#{company.name}] Invitation"
    body      = "#{invitation.sender.name.to_s.titleize} has invited you to sign up as a #{company.name} company staff member.  Your invitation url is #{invite_url}."
    email     = invitation
    message   = MessageCompose.send(sender, subject, body, [email], options)

    return message
  end

end