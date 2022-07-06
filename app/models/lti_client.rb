class LtiClient < ApplicationRecord
  has_many :lti_deployments
  has_many :lti_users
  validates :client_id, uniqueness: { scope: :host }
  include Rails.application.routes.url_helpers

  # Send a signed JWT to canvas to get an Oauth token back. Tokens are short-lived, so
  # a new token should be generated with every lti advantage operation.
  # scopes is a list of scopes allowed on canvas, as defined here
  # https://canvas.instructure.com/doc/api/file.lti_dev_key_config.html
  def get_oauth_token(scopes)
    iat = Time.now.to_i # issued at
    jti_raw = [SecureRandom.alphanumeric(8), iat].join(':').to_s
    jti = Digest::MD5.hexdigest(jti_raw) # Identifier
    payload = {
      iss: root_url,
      sub: client_id,
      aud: Settings.lti.token_endpoint,
      exp: iat + 3600,
      iat: iat,
      jti: jti
    }
    key = OpenSSL::PKey::RSA.new File.read(Settings.lti.key_path)
    jwk = JWT::JWK.new(key)
    token = JWT.encode payload, jwk.keypair, 'RS256', { kid: jwk.kid } # encode and add kid as a header
    # See https://canvas.instructure.com/doc/api/file.oauth_endpoints.html#post-login-oauth2-token
    client_credentials_request = {
      grant_type: 'client_credentials',
      client_assertion_type: 'urn:ietf:params:oauth:client-assertion-type:jwt-bearer',
      scope: scopes.join(' ').to_s,
      client_assertion: token
    }
    oauth_uri = URI(Settings.lti.token_endpoint)
    res = Net::HTTP.post_form(oauth_uri, client_credentials_request)
    JSON.parse(res.body)
  end

  def default_url_options
    Rails.application.config.action_controller.default_url_options
  end
end
