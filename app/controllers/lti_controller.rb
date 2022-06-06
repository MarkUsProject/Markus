class LtiController < ApplicationController
  skip_verify_authorized
  skip_forgery_protection

  before_action :authenticate, :check_course_switch, :check_record,
                except: [:get_canvas_config, :launch, :public_jwk, :redirect_login]

  def get_canvas_config
    # See https://canvas.instructure.com/doc/api/file.lti_dev_key_config.html
    # for example configuration and descriptions of fields
    config = {
      title: I18n.t('markus'),
      description: I18n.t('markus'),
      oidc_initiation_url: lti_launch_url,
      target_link_uri: lti_redirect_login_url,
      scopes: [],
      extensions: [
        {
          domain: request.domain(3),
          tool_id: I18n.t('markus'),
          platform: 'canvas.instructure.com',
          privacy_level: 'public',
          settings: {
            text: I18n.t('lti.launch'),
            placements: [
              {
                text: I18n.t('lti.launch'),
                placement: 'course_navigation',
                target_link_uri: lti_redirect_login_url,
                canvas_icon_class: 'icon-lti',
                default: 'disabled',
                visibility: 'admins',
                windowTarget: '_blank',
                custom_fields: {
                  user_id: '$Canvas.user.id',
                  course_id: '$Canvas.course.id',
                  course_name: '$Canvas.course.name'
                }
              }
            ]
          }
        }
      ],
      public_jwk_url: lti_public_jwk_url,
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
    session[:nonce] = nonce
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
      state: session.id
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
    referrer_uri = URI(request.referer)
    known_jwks = %w[q.utoronto.ca canvas.instructure.com] # only supporting canvas right now
    if params[:id_token].blank? || params[:state] != session.id.to_s || known_jwks.exclude?(referrer_uri.host)
      render 'shared/http_status', locals: { code: '422', message: I18n.t('lti.config_error') }, layout: false
      return
    end

    # Get canvas JWK set
    jwk_url = "#{referrer_uri.scheme}://#{referrer_uri.host}:#{referrer_uri.port}/api/lti/security/jwks"
    canvas_jwks = JSON.parse(Net::HTTP.get_response(URI(jwk_url)).body)
    begin
      decoded_token = JWT.decode(
        params[:id_token],
        nil,
        true, # Verify the signature of this token
        algorithms: ['RS256'],
        iss: 'https://canvas.instructure.com',
        verify_iss: true,
        aud: session[:client_id], # canvas uses client ID as the aud parameter
        verify_aud: true,
        jwks: canvas_jwks
      )
    rescue JWT::Error
      render 'shared/http_status', locals: { code: '422', message: I18n.t('lti.config_error') }, layout: false
      return
    end
    session[:lti_course_id] = decoded_token[0]['https://purl.imsglobal.org/spec/lti/claim/custom']['course_id']
    session[:lti_user_id] = decoded_token[0]['https://purl.imsglobal.org/spec/lti/claim/custom']['user_id']
    session[:lti_course_name] = decoded_token[0]['https://purl.imsglobal.org/spec/lti/claim/custom']['course_name']
    deployment_id = decoded_token[0]['https://purl.imsglobal.org/spec/lti/claim/deployment_id']
    lti_host = URI(request.referer).host
    lti_client = Lti.find_or_create_by(client_id: session[:client_id], deployment_id: deployment_id, host: lti_host)
    session[:lti_client_id] = lti_client.id
    redirect_to root_path
  end

  def public_jwk
    # TODO: implement this function
    render json: { state: 'success' }
  end

  def choose_course
    if request.post?
      begin
        course = Course.find(params[:course])
        lti = Lti.find(session[:lti_client_id])
        lti.update!(course: course)
      rescue StandardError
        flash_message(:error, 'Unsuccessful. Please relaunch MarkUs from your LMS.')
        render 'choose_course'
      else
        flash_message(:success, 'Successfully linked courses')
        redirect_to course_path(course)
      end
    end
  end

  # Define default URL options to not include locale
  def default_url_options(_options = {})
    {}
  end
end
