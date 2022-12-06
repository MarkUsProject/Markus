class LtiDeploymentsController < ApplicationController
  skip_verify_authorized except: [:choose_course]
  skip_forgery_protection except: [:choose_course]

  before_action :authenticate, :check_course_switch, :check_record,
                except: [:get_config, :launch, :public_jwk, :redirect_login]
  before_action(except: [:get_config, :launch, :public_jwk, :redirect_login]) { authorize! }
  before_action :check_host, except: [:choose_course]

  def launch
    lti_params = params[:lti_message_hint].present? ? params : JSON.parse(cookies.encrypted[:lti_params])
    if lti_params.is_a?(Hash)
      lti_params.symbolize_keys!
    end
    if lti_params[:client_id].blank? || lti_params[:login_hint].blank? ||
      lti_params[:target_link_uri].blank? || lti_params[:lti_message_hint].blank?
      head :unprocessable_entity
      return
    end
    nonce = rand(10 ** 30).to_s.rjust(30, '0')
    unless logged_in?
      cookies.encrypted.permanent[:lti_params] = params.to_json
      cookies.encrypted.permanent[:lti_redirect] = request.url
      cookies.encrypted.permanent[:lti_referrer] = request.referer
      redirect_to root_path
      return
    end
    session[:client_id] = lti_params[:client_id]
    session[:iss] = lti_params[:iss]
    auth_params = {
      scope: 'openid',
      response_type: 'id_token',
      client_id: lti_params[:client_id],
      redirect_uri: lti_params[:target_link_uri],
      lti_message_hint: lti_params[:lti_message_hint],
      login_hint: lti_params[:login_hint],
      response_mode: 'form_post',
      nonce: nonce,
      prompt: 'none',
      state: session.id # Binds this request to the LTI response
    }
    if URI(request.referer).host == request.host
      referrer = URI(cookies.encrypted[:lti_referrer])
    else
      referrer = URI(request.referer)
    end

    auth_request_uri = URI("#{referrer.scheme}://#{referrer.host}:#{referrer.port}#{self.class::LMS_REDIRECT_ENDPOINT}")

    http = Net::HTTP.new(auth_request_uri.host, auth_request_uri.port)
    req = Net::HTTP::Post.new(auth_request_uri)
    req.set_form_data(auth_params)

    res = http.request(req)
    location = URI(res['location'])
    location.query = auth_params.to_query
    session[:nonce] = nonce
    redirect_to location.to_s, allow_other_host: true
  end

  def redirect_login
    if params[:id_token].blank? || params[:state] != session.id.to_s
      render 'shared/http_status', locals: { code: '422', message: I18n.t('lti.config_error') }, layout: false
      return
    end
    referrer_uri = URI(request.referer)
    # Get LMS JWK set
    jwk_url = "#{referrer_uri.scheme}://#{referrer_uri.host}:#{referrer_uri.port}#{self.class::LMS_JWK_ENDPOINT}"
    # A list of public keys and associated metadata for JWTs signed by the LMS
    lms_jwks = JSON.parse(Net::HTTP.get_response(URI(jwk_url)).body)
    begin
      decoded_token = JWT.decode(
        params[:id_token], # Encoded JWT signed by LMS
        nil, # If the token is passphrase-protected, set the passphrase here
        true, # Verify the signature of this token
        algorithms: ['RS256'],
        iss: session[:iss],
        verify_iss: true,
        aud: cookies.encrypted[:client_id], # OpenID Connect uses client ID as the aud parameter
        verify_aud: true,
        jwks: lms_jwks # The correct JWK will be selected by matching jwk kid param with id_token kid
      )
    rescue JWT::DecodeError
      render 'shared/http_status', locals: { code: '422', message: I18n.t('lti.config_error') }, layout: false
      return
    end
    lti_params = decoded_token[0]
    unless lti_params['nonce'] == session[:nonce]
      render 'shared/http_status', locals: { code: '422', message: I18n.t('lti.config_error') }, layout: false
      return
    end
    cookies.encrypted[:lti_course_id] = lti_params[LtiDeployment::LTI_CLAIMS[:custom]]['course_id']
    cookies.encrypted[:lti_user_id] = lti_params[LtiDeployment::LTI_CLAIMS[:custom]]['user_id']
    cookies.encrypted[:lti_course_name] = lti_params[LtiDeployment::LTI_CLAIMS[:context]]['title']
    cookies.encrypted[:lti_course_label] = lti_params[LtiDeployment::LTI_CLAIMS[:context]]['label']
    deployment_id = lti_params[LtiDeployment::LTI_CLAIMS[:deployment_id]]
    lti_host = "#{referrer_uri.scheme}://#{referrer_uri.host}:#{referrer_uri.port}"
    lti_client = LtiClient.find_or_create_by(client_id: session[:client_id], host: lti_host)
    lti_deployment = LtiDeployment.find_or_initialize_by(lti_client: lti_client, external_deployment_id: deployment_id)
    lti_deployment.update!(lms_course_name: cookies.encrypted[:lti_course_name],
                           lms_course_id: cookies.encrypted[:lti_course_id])
    cookies.encrypted[:lti_client_id] = lti_client.id
    cookies.encrypted[:lti_deployment_id] = lti_deployment.id
    if lti_params.key?(LtiDeployment::LTI_CLAIMS[:names_role])
      name_and_roles_endpoint = lti_params[LtiDeployment::LTI_CLAIMS[:names_role]]['context_memberships_url']
      names_service = LtiService.find_or_initialize_by(lti_deployment: lti_deployment, service_type: 'namesrole')
      names_service.update!(url: name_and_roles_endpoint)
    end
    if lti_params.key?(LtiDeployment::LTI_CLAIMS[:ags_lineitem])
      grades_endpoints = lti_params[LtiDeployment::LTI_CLAIMS[:ags_lineitem]]
      if grades_endpoints.key?('lineitems')
        lineitem_service = LtiService.find_or_initialize_by(lti_deployment: lti_deployment, service_type: 'agslineitem')
        lineitem_service.update!(url: grades_endpoints['lineitems'])
      end
    end
    redirect_to choose_course
  end

  def public_jwk
    key = OpenSSL::PKey::RSA.new File.read(LtiClient::KEY_PATH)
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
        lti_deployment = record
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
    if known_lti_hosts.exclude?(URI(request.referer).host)
      render 'shared/http_status', locals: { code: '422', message: I18n.t('lti.config_error') },
                                   status: :unprocessable_entity, layout: false
      nil
    end
  end

  def create_course
    new_course = Course.create!(name: params['name'], display_name: params['display_name'], is_hidden: true)
    Instructor.create!(user: current_user, course: new_course)
    lti_deployment = record
    lti_deployment.update!(course: new_course)
    redirect_to edit_course_path(new_course)
  end

  def create_lti_grades
    assessment = Assessment.find(params[:assessment_id])
    lti_deployments = LtiDeployment.where(course: assessment.course, id: params[:lti_deployments])
    lti_deployments.each do |lti|
      lti.get_students
      lti.create_or_update_lti_assessment(assessment)
      lti.create_grades(assessment)
    end
  end

  # Define default URL options to not include locale
  def default_url_options(_options = {})
    {}
  end
end
