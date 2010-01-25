class PdfMailer < ActionMailer::Base
  
  def email(address, subject, pdf_file)
    from(SMTP_FROM)
    recipients(address)
    subject(subject)

    # create pdf attachment
    attachment "application/pdf" do |a|
      a.body = File.read(pdf_file)
      a.filename = "schedule.pdf"
    end
  end

end