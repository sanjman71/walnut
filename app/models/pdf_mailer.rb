class PdfMailer < ActionMailer::Base
  
  def email(address, subject, body, pdf_file)
    from(SMTP_FROM)
    recipients(address)
    subject(subject)
    content_type("multipart/mixed")

    part :content_type => "multipart/alternative" do |a|
      a.part "text/plain" do |p|
        p.body = body
      end

      # a.part "text/html" do |p|
      #   p.body = render_message 'order_placed.text.html.erb', :purchase => purchase
      # end
    end

    # create pdf attachment
    attachment "application/pdf" do |a|
      a.body = File.read(pdf_file)
      a.filename = "schedule.pdf"
    end
  end

end