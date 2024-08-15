if Rails.env.production?
  Rails.application.config.assets.js_compressor = :terser
else
  Rails.application.config.assets.js_compressor = nil
end

Rails.application.config.assets.css_compressor = nil
