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

    # New JupyterLab submission extension endpoints.
    jupyter_session_headers = %w[Accept Authorization X-Jupyter-Base-Url X-Jupyter-Token]

    resource %r{/jupyter/authenticate},
             headers: %w[Accept Content-Type],
             methods: [:post, :options]
    resource %r{/jupyter/courses},
             headers: jupyter_session_headers,
             methods: [:get, :options]
    resource %r{/jupyter/assignments},
             headers: jupyter_session_headers,
             methods: [:get, :options]
    resource %r{/jupyter/submit},
             headers: jupyter_session_headers + %w[Content-Type],
             methods: [:post, :options]
  end
end
