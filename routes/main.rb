# A module to contain routes pertaining to the application's main view (i.e., the chat interface).  
# 
# BE SURE TO REGISTER THE ROUTES APPROPRIATELY IN THE APP'S ENTRY POINT (i.e., app.rb)!

module MainRoutes
    def self.display_app(app)
        app.get '/' do 
            erb :main
        end 
    end

    def self.registered(app)
        display_app(app)
    end
end 