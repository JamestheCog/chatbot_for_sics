# 👩‍⚕️ Chatbot for Serious Illness Conversations

This is an SPA (technically) - a chatbot that's capable of conducting serious illness conversations (or "SICs" for short) with patient's caregivers.  

## 🧰 Setting Up the Project

First, run the command `bundle install` - but not before ensuring that `Gemfile` is present in the project's root directory.  The `Gemfile` contains a total of **seven** dependencies this project relies on:

1. Dependencies for Sinatra (including the `sinatra` gem)
1. `dotenv` to load in environment variables from `.env` files
1. `httparty` for making HTTP requests
1. `encryptor` for dealing with on-the-fly file decryption
1. `mailersend-ruby` for sending emails to specified emails

If you are a collaborator of this project, an `.env` file will be given to you - with it containing the environment variables that are necessary for this project to run!

## ✨ Features 

This is a pretty minimalist application for now, so it only has the following note-worthy features for now:

- Image uploads (but only up to 8 kilobytes as images are base64-encoded before being sent over to the application's backend)
- Ability to chat with the assistant (obviously)
- Night mode (will persist for as long as possible until the user clears out their browser's history)
- Ability to reset conversations

## ⚙️ Running the Application

Run the command `ruby ./app.rb` in the project's root directory after the `bundle install` call!