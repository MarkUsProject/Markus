if Rails.env.production?
  Rails.application.config.assets.js_compressor = Uglifier.new(harmony: true)
  Rails.application.config.assets.css_compressor = :sass
end
