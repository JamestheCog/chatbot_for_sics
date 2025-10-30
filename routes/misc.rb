# A module to contain miscellaneous routes that I can't seem to categorize into an appropriate category.
# Maybe a better organizational structure will come along in the future?

module MiscRoutes 
    def self.ping(app)
        app.get '/ping' do 
            'Warm me up, daddy!'
        end 
    end

    def self.registered(app)
        ping(app)
    end
end