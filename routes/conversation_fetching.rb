=begin
A module to contain routes meant for the fetching of conversations from the SQLitecloud database.
=end

require 'json'
require 'fileutils'
require_relative '../utils/database'
require_relative '../utils/email'

module ConversationRoutes
    def self.fetch_conversations(app)
        app.post '/fetch_conversations/?' do 
            content_type :json
            begin 
                sent_json = JSON.parse(request.body.read)
            rescue JSON::ParseError => e 
                halt 400, {message: "failed to process the JSON object: #{e}"}.to_json
            end 
            halt 400, {message: "JSON object is missing the authorization field."}.to_json unless sent_json.keys.include?('authorization')
            halt 400, {message: "Authorization field is missing a password."}.to_json unless sent_json['authorization'].keys.include?('password')
            halt 403, {message: "Incorrect password provided"}.to_json unless sent_json['authorization']['password'] == ENV['MAIL_PASSWORD']

            begin 
                current_date, attachments = Time.now.strftime('%F'), []
                fetch_conversations_for(current_date)
                Dir.foreach("#{ENV['CONVERSATIONS_PATH']}/#{current_date}") do |user_id| 
                    next if user_id.match?(/^\./)
                    Dir.foreach("#{ENV['CONVERSATIONS_PATH']}/#{current_date}/#{user_id}") do |conversation|
                        next if conversation.match?(/^\./)
                        attachments << {'content' => "#{ENV['CONVERSATIONS_PATH']}/#{current_date}/#{user_id}/#{conversation}",
                                        'filename' => conversation, 'disposition' => 'attachment'}
                    end
                end
                send_email(attachments) if attachments.length > 0
                FileUtils.rm_rf("#{ENV['CONVERSATIONS_PATH']}/#{current_date}")
            rescue StandardError => e 
                puts "[ERROR] An error happened while trying to send conversations: #{e}"
                halt 500, {message: e}.to_json
            ensure
                puts attachments.length > 0 ? "[INFO] Successfully sent the conversations over!" : "[INFO] Nothing to send over for #{current_date}..."
            end
            {status: 200, message: 'action successfully executed'}.to_json
        end
    end
    
    def self.registered(app)
        app.helpers do
            include DatabaseUtils
            include EmailUtils
        end
        fetch_conversations(app)
    end
end