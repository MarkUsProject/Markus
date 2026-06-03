# Be sure to restart your server when you modify this file.

# Avoid CORS issues when API is called from the frontend app.
# Handle Cross-Origin Resource Sharing (CORS) in order to accept cross-origin Ajax requests.

# Read more: https://github.com/cyu/rack-cors
# frozen_string_literal: true

Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    origins 'http://localhost:8889', 'http://127.0.0.1:8889'

    resource '/api/jupyter_submissions',
             headers: :any,
             methods: [:post, :options],
             credentials: true

    resource '/csc108/api/jupyter_submissions',
             headers: :any,
             methods: [:post, :options],
             credentials: true
  end
end
