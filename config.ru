require './app.rb'
run Sinatra::Application

# --- Copied from Grok-4 ---
#
# I've gone ahead and asked Grok-4 for advice on how to increase the file size
# for image uploads - this was what it suggested:
use Rack::Protection::RemoteToken
use Rack::Protection::SessionHijacking

# Increase body size for Puma
Puma::Server::MAX_BODY = 50 * 1024 * 1024