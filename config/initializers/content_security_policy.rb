Rails.application.config.content_security_policy do |policy|
  policy.default_src :self
  policy.font_src    :self
  policy.img_src     :self, :blob
  policy.object_src  :self
  #TODO: set unsafe-eval and unsafe-inline on a per-controller or per-method basis
  policy.script_src  :self, "'strict-dynamic'" # necessary for heic2any TODO: look for alternative so we can disable this
  policy.style_src   :self # necessary for MathJax TODO: look for alternative so we can disable this
  policy.worker_src  :self, :blob
  unless Rails.env.production?
    # http and ws are required so that webpack-dev-server can serve assets
    policy.connect_src :self, :http, :ws
  end
end

Rails.application.config.content_security_policy_nonce_generator = ->(_request) { SecureRandom.base64(16) }
Rails.application.config.content_security_policy_nonce_directives = %(font-src img-src object-src script-src worker-src style-src)
