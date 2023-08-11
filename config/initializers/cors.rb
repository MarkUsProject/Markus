Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    # This enables jupyterhub servers running the markus-jupyter-extension to submit files to MarkUs
    # Add hosts running jupyterhub to the Settings.jupyter_server.hosts settings option.
    origins(*Settings.jupyter_server.hosts)
    resource(%r{/api/courses/\d+/assignments/\d+/submit_file}, headers: :any, methods: :post)
  end
end
