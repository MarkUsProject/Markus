# Be sure to restart your server when you modify this file.

# Define an application-wide content security policy.
# See the Securing Rails Applications Guide for more information:
# https://guides.rubyonrails.org/security.html#content-security-policy-header

Rails.application.configure do
  config.content_security_policy do |policy|
    # Rails defaults:
    # policy.default_src :self, :https
    # policy.font_src    :self, :https, :data
    # policy.img_src     :self, :https, :data
    # policy.object_src  :none
    # policy.script_src  :self, :https
    # policy.style_src   :self, :https

    policy.default_src :self
    policy.script_src :self, "'strict-dynamic'"
    policy.form_action :self
    # Safari doesn't support worker-src and defaults to child-src, blob is required because of the way Safari
    # handles dynamically generated images
    policy.child_src :self, :blob
    # required for Safari < 16
    policy.connect_src :self, :wss
    unless Rails.env.production?
      # http and ws are required so that webpack-dev-server can serve assets
      policy.connect_src :self, :http, :ws
    end

    # Specify URI for violation reports
    # policy.report_uri "/csp-violation-report-endpoint"
  end
  # Generate session nonces for permitted importmap, inline scripts, and inline styles.
  # Rails default:
  # config.content_security_policy_nonce_generator = ->(request) { request.session.id.to_s }
  config.content_security_policy_nonce_generator = ->(_request) { SecureRandom.base64(16) }
  config.content_security_policy_nonce_directives = %w[script-src style-src]

  # Report violations without enforcing the policy.
  # config.content_security_policy_report_only = true
end

# TODO: - at the moment, the following dependencies require unsafe configurations:
#          heic2any: requires script-src 'unsafe-eval'
#          bullet: requires style-src 'unsafe-inline'
#          react-jsonschema-form: required script-src 'unsafe-eval'
#       - These are set as needed in controllers. Eventually we should update
#         all code and dependencies so that these unsafe configs are not needed
