# TODO: - at the moment, the following dependencies require unsafe configurations:
#          heic2any: requires script-src 'unsafe-eval'
#          MathJax: requires style-src 'unsafe-inline' and worker-src blob
#          jquery-ui-timepicker-addon: requires style-src 'unsafe-inline'
#          bullet: requires style-src 'unsafe-inline'
#          react-jsonschema-form: required script-src 'unsafe-eval'
#       - These are set as needed in controllers. Eventually we should update
#         all code and dependencies so that these unsafe configs are not needed

Rails.application.config.content_security_policy do |policy|
  policy.default_src :self
  policy.script_src :self, "'strict-dynamic'"
  policy.form_action :self
  # Safari doesn't support worker-src and defaults to child-src, blob is required because of the way Safari
  # handles dynamically generated images
  policy.child_src :self, :blob
  unless Rails.env.production?
    # http and ws are required so that webpack-dev-server can serve assets
    policy.connect_src :self, :http, :ws
  end
end

Rails.application.config.content_security_policy_nonce_generator = ->(_request) { SecureRandom.base64(16) }
Rails.application.config.content_security_policy_nonce_directives = %(script-src)
