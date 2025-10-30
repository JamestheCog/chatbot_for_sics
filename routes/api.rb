=begin
A module to contain routes for session isolation
=end 

require 'securerandom'
require 'sinatra'
require_relative '../utils/classes/message_logger'
require_relative '../utils/database'
require_relative '../utils/chat'

module APIRoutes
    SECONDS_IN_DAY = 86400
    def self.start_session(app)
        app.post '/api/start_session/?' do 
            content_type :json
            session.clear if !session.keys.include?(:message_logger)
            session[:user_id] = SecureRandom.uuid
            session[:conversation_id] = SecureRandom.uuid
            session[:created_at] = Time.now.to_i
            session[:message_logger] = MessageLogger.new(session[:user_id], session[:conversation_id])
            puts "[INFO] A new session has been initialized."
        end
    end

    def self.send_message(app)
        app.post '/api/send_message/?' do
            content_type :json
            begin 
                data = JSON.parse(request.body.read)
            rescue JSON::ParseError 
                halt 400, {error: 'An invalid JSON payload has been provided'}.to_json
            end 
            halt 401, {status: 'error', message: "There's no valid session."}.to_json unless session[:user_id]
            halt 401, {status: 'error', message: "The user's session has expired."}.to_json if Time.now.to_i - session[:created_at] > SECONDS_IN_DAY
            halt 400, {status: 'error', message: 'No message was provided'}.to_json unless data['message'].is_a?(String)
            halt 400, {status: 'error', message: "There's no MessageLogger object present."}.to_json unless session[:message_logger].is_a?(MessageLogger)
            
            session[:message_logger].log_message(data['message'], 'user', data['img_base64'], data['img_mimetype'])
            returned_message = get_model_response(session[:message_logger].messages)
            session[:message_logger].log_message(returned_message, 'model')
            {status: 'success', returned_message: returned_message}.to_json
        end
    end

    # A route handler for restarting conversations - that reset button at the top of that
    # bar:
    def self.restart_chat(app)
        app.post '/api/restart_chat/?' do 
            begin
                session[:message_logger].new_conversation
                {status: 'success', message: 'conversation restarted successfully..!'}.to_json
            rescue StandardError => e 
                halt 500, {status: 'error', message: "Unable to reset the logger for some reason: #{e}"}.to_json
            end
        end
    end

    def self.registered(app)
        app.helpers do 
            include ChatUtils
        end
        start_session(app)
        send_message(app)
        restart_chat(app)
    end
end