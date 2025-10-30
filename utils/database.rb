# A module to contain helper functions pertaining to the database-related functionality of the application:
require 'httparty'
require 'uri'

module DatabaseUtils
    # A module-level function for checking on the datbase's health - just to ensure that everything is up and 
    # running if needed:
    #
    # (NOTE - Friday, 24th October, 2025): I'm honestly not sure if this function's going to be used or not - if the API is down,
    #                                      wouldn't the caller know about it?
    def is_api_up?(port_number = 8860)
        req = HTTParty.get("https://#{ENV['SQLITECLOUD_PROJECT_ID']}.g2.sqlite.cloud/v2/health", headers: {
            'Accept' => 'application/json', 
            'Authorization' => "Bearer sqlitecloud://#{ENV['SQLITECLOUD_PROJECT_ID']}.g2.sqlite.cloud:#{port_number}?apikey=#{ENV['SQLITECLOUD_API_KEY']}"
        })
        req.keys.map(&:downcase).include?('error') ? false : true
    end

    # Logs a message to be stored in the SQLitecloud database
    def store_message_in_cloud(user_id, convo_id, role, message, port_number = 8860)
        raise TypeError, "'role' needs to be a string of value 'user' or 'model'." unless role.is_a?(String) && ['user', 'model'].include?(role)
        if ![user_id, convo_id, message, role].map{|x| x.is_a?(String)}.reduce(:&)
            raise TypeError, "'user_id', 'convo_id', 'message', and 'role' need to be strings."
        end

        begin 
            cols = HTTParty.get("https://#{ENV['SQLITECLOUD_PROJECT_ID']}.g2.sqlite.cloud/v2/weblite/#{ENV['SQLITECLOUD_DB_NAME']}/#{ENV['SQLITECLOUD_MESSAGE_TABLE']}/columns", headers: {
                'Accept' => 'application/json', 
                'Authorization' => "Bearer #{ENV['SQLITECLOUD_CONNECTION_STRING']}" 
            })
            if cols.keys.include?('data')
                current_time = Time.now.strftime('%Y-%M-%d %H:%M:%S')
                data = cols['data'].map{|x| x['name']}.zip([user_id, convo_id, role, current_time, message]).to_h
                response = HTTParty.post("https://#{ENV['SQLITECLOUD_PROJECT_ID']}.g2.sqlite.cloud/v2/weblite/#{ENV['SQLITECLOUD_DB_NAME']}/#{ENV['SQLITECLOUD_MESSAGE_TABLE']}", 
                    headers: {'Accept' => 'application/json', 'Authorization' => "Bearer #{ENV['SQLITECLOUD_CONNECTION_STRING']}",
                            'Content-Type' => 'application/json'},
                    body: data.to_json)
                puts response.success? ? "[SUCCESS] Message logged." : "[ERROR] An error code while logging a message: #{response.code}"
            else 
                raise StandardError, '[ERROR] Unable to fetch table columns - perhaps the API endpoint has changed?'
            end
        rescue HTTParty::ResponseError => e
            puts "[ERROR] An HTTP error occurred while logging a message: #{e.response.code} - #{e.response.message}"
        rescue StandardError => e 
            puts "[ERROR] A general error occurred while logging a message: #{e.message}"
        end
    end

    # Fetches conversation given a starting date in the "YYYY-MM-DD" format:
    #
    # (NOTE - Friday, 24th November, 2025): I've gone ahead and chunked the second half of this function into a private module method.  That second part's responsible
    #                                       for writing the conversations out into a folder on the server's side (to be sent over to the .env file's specified
    #                                       email address...
    def fetch_conversations_for(date, database_name)
        if [date, database_name].map{|x| x.is_a?(String)}.reduce(:&)
            raise ArgumentError, "'date', 'database_name', 'table_name', and 'api_key' should be strings."
        end

        begin
            sql_statement = "SELECT * FROM #{ENV['SQLITECLOUD_MESSAGE_TABLE']} WHERE #{ENV['SQLITECLOUD_DATE_COL']} LIKE \"?\";".gsub('*', '%2A')
            req = HTTParty.get("https://#{ENV['SQLITECLOUD_PROJECT_ID']}.g2.sqlite.cloud/v2/weblite/sql?sql=#{URI.encode_uri_component(sql_statement)}&bind%5B%5D=#{date}&database=#{ENV['SQLITECLOUD_DB_NAME']}", headers: {
                'Accept' => 'application/json', 
                'Authorization' => "Bearer #{ENV['SQLITECLOUD_CONNECTION_STRING']}"
            })
            if req.keys.include?('data')
                writable_data = req['data'].map{|x| x['user_id']}.zip(Array.new(req['data'].length, []))
                req['data'].each do |row| 
                    writable_data[row['user_id']] << {'role' => row['role'], 'message' => row['message'], 
                                                      'conversation_id' => row['conversation_id'], 'time_messaged' => row['time_messaged']}
                end 
                write_convos_to(req['data'])
            else
                raise ArgumentError, "[ERROR] There's no 'data' field in the payload - did the API endpoint change?"
            end 
        rescue HTTParty::ResponseError => e 
            puts "[ERROR] An HTTP error occurred while writing conversations: #{e.response.code} - #{e.response.message}"
        end
    end

    private 
    def write_convos_to(writing_data, destination_folder = ENV['CONVERSATIONS_PATH'])
        raise TypeError, "'writing_data' needs to be a hash." unless writing_data.is_a?(Hash)
        raise TypeError, "'destination_folder' needs to be a string." unless destination_folder.is_a?(String)
        raise ArgumentError, "'destination_folder' doesn't exist - is there a typo?" unless Dir.exist?(destination_folder) 

        destination_folder = destination_folder.match?(/\/$/) ? destination_folder : destination_folder + '/'
        begin
            writing_data.each do |user, convos| 
                dir_of_interest = destination_folder + "#{user}/"
                Dir.create(dir_of_interest) unless Dir.exist?(dir_of_interest)
                convos.map{|x| x['conversation_id']}.uniq.each do |convo_id|
                    File.open(dir_of_interest + "#{convo_id}.txt", 'w') do |file|
                        file.puts "=== Conversation ID #{convo_id}'s Transcript ===\n\n"
                        writing_data[user].filter{|x| x['conversation_id'] == convo_id}.sort_by{|x| x['time_messaged']}.each do |message|
                            file.puts "[#{message['role']}, #{message['time_messaged']}]\t#{message['message']}"
                        end
                    end 
                end
                puts "[INFO] Done writing conversations out to 'destination_folder' for user ID #{user}!"
            end 
        rescue StandardError => e 
            puts "[ERROR] An error happened while writing conversations: #{e}"
        end
    end
end