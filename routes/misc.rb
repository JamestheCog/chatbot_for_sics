# A module to contain miscellaneous routes that I can't seem to categorize into an appropriate category.
# Maybe a better organizational structure will come along in the future?

require 'httparty'

module MiscRoutes
    DB_PING_ENDPOINT = "https://#{ENV['SQLITECLOUD_PROJECT_ID']}.g2.sqlite.cloud/v2/weblite/sql"
    DB_PING_SQL = 'PRAGMA user_version;'

    def self.ping(app)
        app.get '/ping/?' do 
            'Warm me up, daddy!'
        end 
    end

    def self.ping_database(app)
        app.get '/ping_database/?' do
            content_type :json
            response = HTTParty.post(DB_PING_ENDPOINT, 
                                     headers: {'Content-Type' => 'application/json', 'accept' => 'application/json',
                                               'Authorization' => "Bearer #{ENV['SQLITECLOUD_CONNECTION_STRING']}"},
                                     contents: {'sql' => DB_PING_SQL, 'database' => ENV['SQLITECLOUD_DB_NAME']}.to_json)
            if response.success?
                puts "[INFO] Successfully woke database up!"
                {'status' => 200, 'message' => 'database woken up'}.to_json
            else 
                puts "[ERROR] Unable to wake database up!"
                halt response.code, {'status' => response.code, 'message' => response.message}.to_json
            end
        end
    end

    def self.registered(app)
        ping(app)
        ping_database(app)
    end
end