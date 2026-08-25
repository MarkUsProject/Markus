# Be sure to restart your server when you modify this file.

# Avoid CORS issues when API is called from the frontend app.
# Handle Cross-Origin Resource Sharing (CORS) in order to accept cross-origin Ajax requests.

# Read more: https://github.com/cyu/rack-cors

Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    # Jupyter/JupyterHub browser origins that are permitted to submit to MarkUs.
    origins(*Settings.jupyter_server.hosts)

    # Legacy MarkUs Jupyter submission API.
    resource %r{/api/courses/\d+/assignments/\d+/submit_file},
             headers: :any,
             methods: [:post]

    # New JupyterLab extension submission endpoint.
    resource %r{/jupyter/submit},
             headers: :any,
             methods: [:post, :options]
  end
end
