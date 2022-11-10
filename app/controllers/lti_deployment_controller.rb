class LtiDeploymentController < ApplicationController
  skip_verify_authorized except: [:choose_course]
  skip_forgery_protection except: [:choose_course]

  before_action :authenticate, :check_course_switch, :check_record,
                except: [:get_config, :launch, :public_jwk, :redirect_login]
  before_action(except: [:get_config, :launch, :public_jwk, :redirect_login]) { authorize! }
  before_action :check_host, except: [:choose_course]

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

    auth_request_uri = URI("#{referrer.scheme}://#{referrer.host}:#{referrer.port}#{lms_redirect_endpoint}")

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
    jwk_url = "#{referrer_uri.scheme}://#{referrer_uri.host}:#{referrer_uri.port}#{lms_jwk_endpoint}"
    # A list of public keys and associated metadata for JWTs signed by canvas
    lms_jwks = JSON.parse(Net::HTTP.get_response(URI(jwk_url)).body)
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
    session[:lti_course_id] = lti_params[LtiDeployment::LTI_CLAIMS[:custom]]['course_id']
    session[:lti_user_id] = lti_params[LtiDeployment::LTI_CLAIMS[:custom]]['user_id']
    session[:lti_course_name] = lti_params[LtiDeployment::LTI_CLAIMS[:context]]['title']
    session[:lti_course_label] = lti_params[LtiDeployment::LTI_CLAIMS[:context]]['label']
    deployment_id = lti_params[LtiDeployment::LTI_CLAIMS[:deployment_id]]
    lti_host = "#{referrer_uri.scheme}://#{referrer_uri.host}:#{referrer_uri.port}"
    lti_client = LtiClient.find_or_create_by(client_id: session[:client_id], host: lti_host)
    lti_deployment = LtiDeployment.find_or_initialize_by(lti_client: lti_client, external_deployment_id: deployment_id)
    lti_deployment.update!(lms_course_name: session[:lti_course_name],
                           lms_course_id: session[:lti_course_id])
    session[:lti_client_id] = lti_client.id
    session[:lti_deployment_id] = lti_deployment.id
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
    redirect_to root_path
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

  def lms_jwk_endpoint
    self.class::LMS_JWK_ENDPOINT
  end

  def lms_redirect_endpoint
    self.class::LMS_REDIRECT_ENDPOINT
  end

  # Define default URL options to not include locale
  def default_url_options(_options = {})
    {}
  end
end
