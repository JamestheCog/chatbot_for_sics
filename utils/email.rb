=begin
For email-related constants:
=end

require 'mailersend-ruby'

module EmailUtils
    MESSAGE = <<~EMAIL_BODY
        Hey!  Do find the attached conversations in the email for #{Time.now.strftime('%F')}...
    EMAIL_BODY
    MESSAGE_TITLE = "SICs for #{Time.now.strftime('%Y-%m-%d')}"
    FIELDS_OF_INTEREST = ['content', 'filename', 'disposition']

    # Does what it says it does - with the SendMailer API for rubyists, that is.  Do check out their 
    # official GitHub repo for more information
    def send_email(attachments)
        begin 
            ms_client = Mailersend::Client.new(ENV['SEMDMAIL_API_TOKEN'])
            email = Mailersend::Email.new(ms_client)
            email.add_recipients('email' => ENV['SENDMAIL_EMAIL'], 'name' => ENV['SENDMAIL_NAME'])
            email.add_subject(MESSAGE_TITLE)
            email.add_text(MESSAGE.strip)
            attachments.each{|item| email.add_attachment(content: Base64.encode64(File.read(item['content'])), filename: item['filename'],
                                                         disposition: item['disposition'])}
            email.send
        rescue StandardError => e
            puts "[ERROR] Failed to send an email: #{e}"
        end
        puts "[INFO] Email sent successfully!"
    end

    private 
    def is_valid_attachment?(attachments) 
        puts attachments    
        return false unless attachments.is_a?(Array)
        attachments.each do |item|
            return false unless item.is_a?(Hash)
            return false unless attachments.map{|x| FIELDS_OF_INTEREST.include?(x)}.reduce(:&)
            return false unless item['content'].split('/')[-1].trim == item['filename']
        end
        true
    end
end