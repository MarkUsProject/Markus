Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    origins(*Settings.jupyter_server.hosts)
    resource(%r{/api/courses/\d+/assignments/\d+/submit_file}, headers: :any, methods: :post)
  end
end
