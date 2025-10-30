# A Ruby file to contain a custom-built logger class for logging user messages sent to 
# the application

require_relative '../database'
require 'securerandom'

=begin

=end
class MessageLogger
    include DatabaseUtils 
    attr_accessor :user_id, :conversation_id, :messages

    def initialize(user_id, convo_id)
        @messages = []
        @user_id = user_id
        @conversation_id = convo_id
    end

    def log_message(message, role, base64_img = nil, img_mimetype = nil)
        raise ArgumentError, "'message' and 'role' need to be strings" unless message.is_a?(String) && role.is_a?(String)
        raise ArgumentError, "'role' should either be of value 'user' or 'model'" unless ['user', 'model'].include?(role)
        raise ArgumentError, "'base64_img' needs to be a nil or a string." unless base64_img.nil? || base64_img.is_a?(String)
        if !base64_img.nil? && base64_img.is_a?(String) && base64_img.trim.length > 0
            if img_mimetype.nil? && !img_mimetype.is_a?(String) && img_mimetype.trim.length == 0
                raise ArgumentError, "img_mimetype must be a string if base64_img is non-nil and a non-empty string."
            end
            img_mimetype.downcase!
            raise ArgumentError, "img_mimetype is invalid." unless img_mimetype.match?(/image\/(png|jpg)/)
        end
        store_message_in_cloud(@user_id, @conversation_id, role, message)
        if base64_img.nil? || base64_img.strip.length == 0
            @messages << {'role' => role, 'parts' => [{'text' => message}, {'inline_data' => {'mime_type' : img_mimetype, 'data' : base64_img}}]}
        else 
            @messages << {'role' => role, 'parts' => [{'text' => message}]}
        end
    end

    def new_conversation()
        @messages = []
        @conversation_id = SecureRandom.uuid
    end
end