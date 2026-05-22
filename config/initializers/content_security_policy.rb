# Be sure to restart your server when you modify this file.

# Define an application-wide content security policy.
# See the Securing Rails Applications Guide for more information:
# https://guides.rubyonrails.org/security.html#content-security-policy-header

Rails.application.configure do
  config.content_security_policy do |policy|
    policy.default_src :self
    policy.font_src :self
    policy.form_action :self

    # img_src is overridden in specific controller methods. Rails default:
    # policy.img_src     :self, :https, :data

    policy.object_src :none
    policy.style_src_elem :self   # <style> elements and <link> stylesheets; nonce added below
    policy.style_src_attr :unsafe_inline  # style="..." attributes (required by Jcrop, jQuery UI, etc.)

    # child-src is the worker-src fallback for Safari < 16; blob: is required for heic2any's blob Worker
    # and for blob: image URLs created by URL.createObjectURL on those same pages.
    policy.child_src :self, :blob
    policy.worker_src :self, :blob

    # Notes:
    # 1. The following dependencies still require script-src 'unsafe-eval' on specific pages;
    #    these are overridden per action in the relevant controllers:
    #     - heic2any (results, submissions) - libheif compiled via Emscripten uses new Function()
    #     - @rjsf/validator-ajv8 (automated_tests#manage) - ajv compiles JSON schemas via new Function()
    # 2. @rails/ujs dynamically inserts <script> tags when a controller responses with render js: ...
    #    These require 'strict-dynamic' to execute.
    if Rails.env.production?
      policy.script_src :self, "'strict-dynamic'"
    else
      # Allow eval for use in Webpack-generated source maps
      policy.script_src :self, "'strict-dynamic'", :unsafe_eval
    end

    if Rails.env.production?
      policy.connect_src :self, :wss
    else
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
  config.content_security_policy_nonce_directives = %w[script-src style-src-elem]

  # Report violations without enforcing the policy.
  # config.content_security_policy_report_only = true
end
