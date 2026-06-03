# Optional development-only example.
# Use only if the JupyterLab frontend is blocked by CORS when posting to MarkUs.
# Prefer a stricter production configuration with a known JupyterHub origin.
#
# Rails.application.config.middleware.insert_before 0, Rack::Cors do
#   allow do
#     origins 'http://localhost:8888', 'http://localhost:8889', 'http://127.0.0.1:8888', 'http://127.0.0.1:8889'
#     resource '/api/jupyter_submissions',
#              headers: :any,
#              methods: [:post, :options],
#              credentials: true
#   end
# end
