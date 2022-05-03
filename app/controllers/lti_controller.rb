class LtiController < ApplicationController
  skip_before_action :verify_authenticity_token, only: [:get_config, :public_jwk]
  skip_verify_authorized

  before_action :authenticate, :check_course_switch, :check_record,
                except: [:get_config, :public_jwk]

  after_action :allow_iframe, only: [:get_config, :public_jwk]

  def allow_iframe
    response.headers.delete 'X-Frame-Options'
  end

  def get_config
    @lti_error = nil
    config_data = { title: 'MarkUs',
                    description: 'MarkUs',
                    oidc_initiation_url: "#{root_url}lti/launch",
                    target_link_uri: "#{root_url}login",
                    grant_types: %w[client_credentials implicit],
                    public_jwk_url: "#{root_url}lti/jwk",
                    application_type: 'web',
                    response_types: ['id_token'],
                    initiate_login_uri: "#{root_url}lti/launch",
                    redirect_uris: ["#{root_url}lti/launch"],
                    client_name: 'MarkUs',
                    jwks_uri: "#{root_url}lti/jwk",
                    token_endpoint_auth_method: 'private_key_jwt',
                    scope: 'https://purl.imsglobal.org/spec/lti-ags/scope/lineitem ' \
                           'https://purl.imsglobal.org/spec/lti-ags/scope/result.readonly ' \
                           'https://purl.imsglobal.org/spec/lti-ags/scope/score ' \
                           'https://purl.imsglobal.org/spec/lti-nrps/scope/contextmembership.readonly' \
                           'https://purl.imsglobal.org/spec/lti-ts/scope/toolsetting',
                    'https://purl.imsglobal.org/spec/lti-tool-configuration': {
                      title: 'MarkUs',
                      description: 'MarkUs',
                      target_link_uri: "#{root_url}/login",
                      domain: root_url,
                      secondary_domains: ['host.docker.internal:3000'],
                      claims: %w[
                        sub
                        iss
                        name
                        given_name
                        family_name
                        email
                      ],
                      privacy_level: 'public'
                    } }

    if params[:openid_configuration].blank?
      @lti_error = 'OpenID configuration URL not present in params'
      render 'config_error'
    end

    uri = URI(params[:openid_configuration])
    res = JSON.parse(Net::HTTP.get_response(uri).body)
    reg_uri = URI(res['registration_endpoint'])
    # LTI requires host to match - note less strict than OpenID Connect
    unless reg_uri.host == URI(res['issuer']).host
      @lti_error = 'Issuer and registration host mismatch'
      render 'config_error', layout: 'layouts/main'
    end

    http = Net::HTTP.new(reg_uri.host, reg_uri.port)
    post_req = Net::HTTP::Post.new(reg_uri.request_uri)

    # registration_token is optional, see
    # https://www.imsglobal.org/spec/lti-dr/v1p0#step-1-registration-initiation-request
    post_req['Authorization'] = "Bearer #{params[:registration_token]}" if params[:registration_token]
    post_req['Content-Type'] = 'application/json'
    post_req.body = config_data.to_json

    response = http.request(post_req)
    returned_configuration = JSON.parse(response.body)
    lti_configuration = Lti.find_or_create_by(client_id: returned_configuration['client_id'],
                                              deployment_id: returned_configuration["https:\/\/purl.imsglobal.org\/spec\/lti-tool-configuration"]['deployment_id'])
    lti_configuration.update!(config: returned_configuration)

    render 'lti/get_config', layout: 'layouts/main'
  end

  def public_jwk
    private_key = Oauthkey.first_or_create(private_key: OpenSSL::PKey::RSA.generate(2048).to_s)
    key = OpenSSL::PKey::RSA.new private_key.private_key
    public_key = key.public_key
    JSON::JWK.new(private_key) # => JWK including RSA private key components
    pub_jwk = JSON::JWK.new(public_key)
    render json: pub_jwk.to_json
  end

  def lti_params
    params.permit(:openid_configuration)
  end
end
