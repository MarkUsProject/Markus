if Rails.env.production?
  Rails.application.config.assets.js_compressor = :terser
  Rails.application.config.assets.css_compressor = :sass
else
  Rails.application.config.assets.js_compressor = nil
  Rails.application.config.assets.css_compressor = nil
end
