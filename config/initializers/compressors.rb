if Rails.env.production?
  Rails.application.config.assets.js_compressor = :terser
  Rails.application.config.assets.css_compressor = :sass
end
