class LtiDeploymentController < ApplicationController
  skip_verify_authorized except: [:choose_course]
  skip_forgery_protection except: [:choose_course]

  before_action :authenticate, :check_course_switch, :check_record,
                except: [:get_canvas_config, :launch, :public_jwk, :redirect_login]
  before_action(except: [:get_canvas_config, :launch, :public_jwk, :redirect_login]) { authorize! }
  before_action :check_host, except: [:choose_course]

  def get_canvas_config
    # See https://canvas.instructure.com/doc/api/file.lti_dev_key_config.html
    # for example configuration and descriptions of fields
    config = {
      title: I18n.t('markus'),
      description: I18n.t('markus'),
      oidc_initiation_url: lti_deployment_launch_url,
      target_link_uri: lti_deployment_redirect_login_url,
      scopes: ['https://purl.imsglobal.org/spec/lti-nrps/scope/contextmembership.readonly'],
      extensions: [
        {
          domain: request.domain(3),
          tool_id: I18n.t('markus'),
          platform: 'canvas.instructure.com',
          privacy_level: 'public', # Include user name information
          settings: {
            text: I18n.t('lti.launch'),
            placements: [
              {
                text: I18n.t('lti.launch'),
                placement: 'course_navigation',
                canvas_icon_class: 'icon-lti',
                default: 'disabled',
                visibility: 'admins',
                windowTarget: '_blank'
              }
            ]
          }
        }
      ],
      public_jwk_url: lti_deployment_public_jwk_url,
      custom_fields: {
        user_id: '$Canvas.user.id',
        course_id: '$Canvas.course.id',
        course_name: '$Canvas.course.name'
      }
    }

    render json: config.to_json
  end

  def launch
    if params[:client_id].blank? || params[:login_hint].blank? ||
      params[:target_link_uri].blank? || params[:lti_message_hint].blank?
      head :unprocessable_entity
      return
    end
    nonce = rand(10 ** 30).to_s.rjust(30, '0')
    session[:client_id] = params[:client_id]
    session[:nonce] = nonce # Nonce should be present in the JWT sent to MarkUs, and must be verified
    auth_params = {
      scope: 'openid',
      response_type: 'id_token',
      client_id: params[:client_id],
      redirect_uri: params[:target_link_uri],
      lti_message_hint: params[:lti_message_hint],
      login_hint: params[:login_hint],
      response_mode: 'form_post',
      nonce: nonce,
      prompt: 'none',
      state: session.id # Binds this request to the LTI response
    }
    referrer = URI(request.referer)

    # TODO: generalize this to platforms other than canvas.
    auth_request_uri = URI("#{referrer.scheme}://#{referrer.host}:#{referrer.port}/api/lti/authorize_redirect")

    http = Net::HTTP.new(auth_request_uri.host, auth_request_uri.port)
    req = Net::HTTP::Post.new(auth_request_uri)
    req.set_form_data(auth_params)

    res = http.request(req)
    location = res['location']
    redirect_to location
  end

  def redirect_login
    if params[:id_token].blank? || params[:state] != session.id.to_s
      render 'shared/http_status', locals: { code: '422', message: I18n.t('lti.config_error') }, layout: false
      return
    end

    referrer_uri = URI(request.referer)
    # Get canvas JWK set
    jwk_url = "#{referrer_uri.scheme}://#{referrer_uri.host}:#{referrer_uri.port}/api/lti/security/jwks"
    # A list of public keys and associated metadata for JWTs signed by canvas
    canvas_jwks = JSON.parse(Net::HTTP.get_response(URI(jwk_url)).body)
    begin
      decoded_token = JWT.decode(
        params[:id_token], # Encoded JWT signed by canvas
        nil, # If the token is passphrase-protected, set the passphrase here
        true, # Verify the signature of this token
        algorithms: ['RS256'],
        iss: "#{referrer_uri.scheme}://#{referrer_uri.host}",
        verify_iss: true,
        aud: session[:client_id], # canvas uses client ID as the aud parameter
        verify_aud: true,
        jwks: canvas_jwks # The correct JWK will be selected by matching jwk kid param with id_token kid
      )
    rescue JWT::DecodeError
      render 'shared/http_status', locals: { code: '422', message: I18n.t('lti.config_error') }, layout: false
      return
    end
    unless decoded_token[0]['nonce'] == session[:nonce]
      render 'shared/http_status', locals: { code: '422', message: I18n.t('lti.config_error') }, layout: false
      return
    end
    session[:lti_course_id] = decoded_token[0]['https://purl.imsglobal.org/spec/lti/claim/custom']['course_id']
    session[:lti_user_id] = decoded_token[0]['https://purl.imsglobal.org/spec/lti/claim/custom']['user_id']
    session[:lti_course_name] = decoded_token[0]['https://purl.imsglobal.org/spec/lti/claim/custom']['course_name']
    deployment_id = decoded_token[0]['https://purl.imsglobal.org/spec/lti/claim/deployment_id']
    lti_host = "#{referrer_uri.scheme}://#{referrer_uri.host}:#{referrer_uri.port}"
    lti_client = LtiClient.find_or_create_by(client_id: session[:client_id], host: lti_host)
    lti_deployment = LtiDeployment.find_or_create_by(lti_client: lti_client, external_deployment_id: deployment_id)
    session[:lti_client_id] = lti_client.id
    session[:lti_deployment_id] = lti_deployment.id
    if decoded_token[0].key?('https://purl.imsglobal.org/spec/lti-nrps/claim/namesroleservice')
      name_and_roles_endpoint = decoded_token[0]['https://purl.imsglobal.org/spec/lti-nrps/claim/namesroleservice']['context_memberships_url']
      names_service = LtiService.find_or_initialize_by(lti_deployment: lti_deployment, service_type: 'namesrole')
      names_service.update!(url: name_and_roles_endpoint)
    end
    redirect_to root_path
  end

  def public_jwk
    key = OpenSSL::PKey::RSA.new File.read(Settings.lti.key_path)
    jwk = JWT::JWK.new(key)
    render json: { keys: [jwk.export] }
  end

  def choose_course
    if request.post?
      begin
        course = Course.find(params[:course])
        unless Instructor.exists?(user: real_user, course: course)
          flash_message(:error, t('lti.course_link_error'))
          render 'choose_course'
          return
        end
        lti_deployment = LtiDeployment.find(session[:lti_deployment_id])
        lti_deployment.update!(course: course)
      rescue StandardError
        flash_message(:error, t('lti.course_link_error'))
        render 'choose_course'
      else
        flash_message(:success, t('lti.course_link_success', markus_course_name: course.name))
        redirect_to course_path(course)
      end
    end
  end

  def check_host
    known_lti_hosts = Settings.lti.domains
    if known_lti_hosts.exclude?(request.host)
      render 'shared/http_status', locals: { code: '422', message: I18n.t('lti.config_error') }, layout: false
      nil
    end
  end

  # Define default URL options to not include locale
  def default_url_options(_options = {})
    {}
  end
end
