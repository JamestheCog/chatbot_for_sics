=begin

=end

require 'sinatra'
require 'openssl' 

module ChatUtils
    GEMINI_POST_API = 'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent'

    # Fetches the model's response (it's currently Gemini 2.5 Flash, but do consider writing another function, if not 
    # augmenting this function if another model / provider is used in the future):
    def get_model_response(conversation_history, num_attempts = 3)
        base_prompt = get_bot_prompt()
        raise ArgumentError, "'base_prompt' is not a string." unless base_prompt.is_a?(String)
        raise ArgumentError, "'conversation_history' is not in the right format." unless conversation_history.is_a?(Array)
        conversation_history.each do |item|
            raise ArgumentError, "There's an illegal item in at least one of the items in `conversation_history`" unless item.keys.include?('role') && item.keys.include?('parts')
            item['parts'].each do |message|
                raise ArgumentError, "An item in `conversation_history` is missing a `text` parameter." unless message.keys.include?('text')
                raise ArgumentError, "The provided message needs to be a string." unless message['text'].is_a?(String)
            end
        end
        raise ArgumentError, "'num_attempts' needs to be an integer" unless num_attempts.is_a?(Integer)

        begin 
            attempt_count, message_returned = 1, nil
            num_attempts.times do |attempt|
                req = HTTParty.post(GEMINI_POST_API, 
                    headers: {'Content-Type' => 'application/json', 'x-goog-api-key' => ENV['GEMINI_API_KEY']},
                    body: {'system_instruction' => {'parts' => [{'text' => base_prompt}]}, 'contents' => conversation_history}.to_json    
                )
                
                if req.keys.include?('candidates')
                    message_returned = req['candidates'][0]['content']['parts'][0]['text']
                    break
                else
                    puts "[INFO] Failed to get response from Gemini's servers - trying again (attempt ##{attempt_count} out of #{num_attempts})"
                    sleep (rand * 2) + 2**attempt_count
                end
            end
            message_returned.nil? ? "[ERROR] Failed to fetch the model's response!" : message_returned
        rescue HTTParty::ResponseError => e
            puts "[ERROR] A network error while trying to obtain a response from Gemini's servers: #{e.message}"
        rescue StandardError => e 
            puts "[ERROR] A general error happened while trying to fetch a response from Gemini's servers: #{e.message}"
        end
    end

    private
    def get_bot_prompt()
        salt, iv, encrypted = File.read(ENV['PROMPT_PATH']).split(':').map { |x| Base64.strict_decode64(x) }
        key, decipher = OpenSSL::PKCS5.pbkdf2_hmac(ENV['ENC_PASSWORD'], salt, ENV['ENC_ITER'].to_i, 32, 'sha256'), OpenSSL::Cipher.new('aes-256-cbc')
        decipher.decrypt
        decipher.key, decipher.iv = key, iv
        decipher.update(encrypted) + decipher.final
    end
end