require 'sinatra/base'
require 'dotenv/load'
require 'securerandom'
require 'rack/session/cookie'

# User-defined modules here:
require_relative 'routes/main'
require_relative 'routes/misc'
require_relative 'routes/api'
require_relative 'routes/conversation_fetching'
require_relative 'utils/classes/message_logger'

# Load in any environment variables here:
Dotenv.load!

# The application's entry point:
class App < Sinatra::Base 
    # Set up the Sinatra application's configurations...
    configure do 
        enable :logging, :sessions
        set :session_secret, ENV['SESSION_SECRET']
        set :public_folder, 'static'
        set :session,
            httponly: true, secure: ENV['RACK_ENV'] == 'production',
            same_site: :strict
        set :show_exceptions, false

        use Rack::Session::Cookie,
            :key => 'rack.session',
            :path => '/',
            :expire_after => 3600,
            :secret => ENV['SESSION_SECRET'] || SecureRandom.uuid,
            :max_age => 8192
    end 

    # Register the routes here before running them below:
    register MainRoutes 
    register APIRoutes
    register MiscRoutes
    register ConversationRoutes

    run! if __FILE__ == $PROGRAM_NAME
end 