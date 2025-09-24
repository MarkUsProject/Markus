class LtiDeploymentsController < ApplicationController
  skip_verify_authorized except: [:choose_course]
  skip_forgery_protection except: [:choose_course]

  before_action :authenticate, :check_course_switch, :check_record,
                except: [:get_config, :launch, :public_jwk, :redirect_login]
  before_action(except: [:get_config, :launch, :public_jwk, :redirect_login]) { authorize! }
  before_action :check_host, only: [:launch, :redirect_login]

  USE_SECURE_COOKIES = !Rails.env.local?

  def launch
    if params[:client_id].blank? || params[:login_hint].blank? ||
      params[:target_link_uri].blank? || params[:lti_message_hint].blank?
      head :unprocessable_entity
      return
    end
    nonce = rand(10 ** 30).to_s.rjust(30, '0')
    session_nonce = rand(10 ** 30).to_s.rjust(30, '0')
    lti_launch_data = {}
    lti_launch_data[:client_id] = params[:client_id]
    lti_launch_data[:iss] = params[:iss]
    lti_launch_data[:nonce] = nonce
    lti_launch_data[:state] = session_nonce
    cookies.permanent.encrypted[:lti_launch_data] =
      { value: JSON.generate(lti_launch_data), expires: 1.hour.from_now, same_site: :none, secure: USE_SECURE_COOKIES }
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
      state: session_nonce
    }
    auth_request_uri = construct_redirect_with_port(request.referer, endpoint: self.class::LMS_REDIRECT_ENDPOINT)

    http = Net::HTTP.new(auth_request_uri.host, auth_request_uri.port)
    http.use_ssl = true if auth_request_uri.instance_of? URI::HTTPS
    req = Net::HTTP::Post.new(auth_request_uri)
    req.set_form_data(auth_params)

    res = http.request(req)
    location = URI(res['location'])
    location.query = auth_params.to_query
    redirect_to location.to_s, allow_other_host: true
  end

  def redirect_login
    if request.post?
      lti_launch_data = JSON.parse(cookies.encrypted[:lti_launch_data]).symbolize_keys

      if params[:id_token].blank? || params[:state] != lti_launch_data[:state]
        render 'shared/http_status', locals: { code: '422', message: I18n.t('lti.config_error') },
                                     layout: false
        return
      end
      # Get LMS JWK set
      jwk_url = construct_redirect_with_port(request.referer, endpoint: self.class::LMS_JWK_ENDPOINT)
      # A list of public keys and associated metadata for JWTs signed by the LMS
      lms_jwks = JSON.parse(Net::HTTP.get_response(jwk_url).body)
      begin
        decoded_token = JWT.decode(
          params[:id_token], # Encoded JWT signed by LMS
          nil, # If the token is passphrase-protected, set the passphrase here
          true, # Verify the signature of this token
          algorithms: ['RS256'],
          iss: lti_launch_data[:iss],
          verify_iss: true,
          aud: lti_launch_data[:client_id], # OpenID Connect uses client ID as the aud parameter
          verify_aud: true,
          jwks: lms_jwks # The correct JWK will be selected by matching jwk kid param with id_token kid
        )
        lti_params = decoded_token[0]
        unless lti_params['nonce'] == lti_launch_data[:nonce]
          render 'shared/http_status', locals: { code: '422', message: I18n.t('lti.config_error') },
                                       layout: false
          return
        end
      rescue JWT::DecodeError
        render 'shared/http_status', locals: { code: '422', message: I18n.t('lti.config_error') },
                                     layout: false
        return
      end

      lti_data = { host: construct_redirect_with_port(request.referer).to_s,
                   client_id: lti_launch_data[:client_id],
                   deployment_id: lti_params[LtiDeployment::LTI_CLAIMS[:deployment_id]],
                   lms_course_name: lti_params[LtiDeployment::LTI_CLAIMS[:context]]['title'],
                   lms_course_label: lti_params[LtiDeployment::LTI_CLAIMS[:context]]['label'],
                   lms_course_id: lti_params[LtiDeployment::LTI_CLAIMS[:custom]]['course_id'] }
      if lti_params.key?(LtiDeployment::LTI_CLAIMS[:names_role])
        name_and_roles_endpoint = lti_params[LtiDeployment::LTI_CLAIMS[:names_role]]['context_memberships_url']
        lti_data[:names_role_service] = name_and_roles_endpoint
      end
      if lti_params.key?(LtiDeployment::LTI_CLAIMS[:ags_lineitem])
        grades_endpoints = lti_params[LtiDeployment::LTI_CLAIMS[:ags_lineitem]]
        if grades_endpoints.key?('lineitems')
          lti_data[:line_items] = grades_endpoints['lineitems']
        end
      end
      lti_data[:lti_user_id] = lti_params[LtiDeployment::LTI_CLAIMS[:user_id]]
      unless logged_in?
        lti_data[:lti_redirect] = request.url
        cookies.encrypted.permanent[:lti_data] =
          { value: JSON.generate(lti_data), expires: 1.hour.from_now, same_site: :none, secure: USE_SECURE_COOKIES }
        redirect_to root_path
        return
      end
    elsif logged_in? && cookies.encrypted[:lti_data].present?
      lti_data = JSON.parse(cookies.encrypted[:lti_data]).symbolize_keys
      cookies.delete(:lti_data)
    else
      render 'shared/http_status', locals: { code: '422', message: I18n.t('lti.config_error') },
                                   layout: false
      return
    end
    lti_client = LtiClient.find_or_create_by(client_id: lti_data[:client_id], host: lti_data[:host])
    lti_deployment = LtiDeployment.find_or_initialize_by(lti_client: lti_client,
                                                         external_deployment_id: lti_data[:deployment_id],
                                                         lms_course_id: lti_data[:lms_course_id])
    lti_deployment.update!(lms_course_name: lti_data[:lms_course_name])
    session[:lti_course_label] = lti_data[:lms_course_label]
    if lti_data.key?(:names_role_service)
      names_service = LtiService.find_or_initialize_by(lti_deployment: lti_deployment, service_type: 'namesrole')
      names_service.update!(url: lti_data[:names_role_service])
    end
    if lti_data.key?(:line_items)
      lineitem_service = LtiService.find_or_initialize_by(lti_deployment: lti_deployment, service_type: 'agslineitem')
      lineitem_service.update!(url: lti_data[:line_items])
    end
    LtiUser.find_or_create_by(user: @real_user, lti_client: lti_client,
                              lti_user_id: lti_data[:lti_user_id])
    if lti_deployment.course.nil?
      # Redirect to course picker page
      redirect_to choose_course_lti_deployment_path(lti_deployment)
    else
      redirect_to course_path(lti_deployment.course)
    end
  ensure
    cookies.delete(:lti_launch_data)
  end

  def public_jwk
    key = OpenSSL::PKey::RSA.new File.read(LtiClient::KEY_PATH)
    jwk = JWT::JWK.new(key)
    render json: { keys: [jwk.export] }
  end

  def choose_course
    @lti_deployment = record
    if request.post?
      begin
        course = Course.find(params[:course])
        unless allowed_to?(:manage_lti_deployments?, course, with: CoursePolicy)
          flash_message(:error, t('lti.course_link_error'))
          render 'choose_course'
          return
        end
        @lti_deployment.update!(course: course)
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
    known_lti_hosts << URI(root_url).host
    if known_lti_hosts.exclude?(URI(request.referer).host)
      render 'shared/http_status', locals: { code: '422', message: I18n.t('lti.config_error') },
                                   status: :unprocessable_entity, layout: false
      nil
    end
  end

  def create_course
    if LtiConfig.respond_to?(:allowed_to_create_course?) && !LtiConfig.allowed_to_create_course?(record)
      @title = I18n.t('lti.course_creation_denied')
      @message = format(
        Settings.lti.unpermitted_new_course_message,
        course_name: record.lms_course_name
      )
      render 'message', status: :forbidden
      return
    end

    name = params['name'].gsub(/[^a-zA-Z0-9\-_]/, '-')  # Sanitize name to comply with Course name validation
    new_course = Course.find_or_initialize_by(name: name)
    unless new_course.new_record?
      flash_message(:error, I18n.t('lti.course_exists'))
      redirect_to choose_course_lti_deployment_path
      return
    end
    new_course.update!(display_name: params['display_name'], is_hidden: true)
    if current_user.admin_user?
      AdminRole.find_or_create_by(user: current_user, course: new_course)
    else
      Instructor.find_or_create_by(user: current_user, course: new_course)
    end
    lti_deployment = record
    lti_deployment.update!(course: new_course)
    redirect_to edit_course_path(new_course)
  end

  def get_config
    raise NotImplementedError
  end

  # Takes a string and returns a URI corresponding to the redirect
  # endpoint for the lms
  def construct_redirect_with_port(url, endpoint: nil)
    referer = URI(url)
    referer_host = "#{referer.scheme}://#{referer.host}"
    referer_host_with_port = "#{referer_host}:#{referer.port}"
    referer_host = referer_host_with_port if referer.to_s.start_with?(referer_host_with_port)
    URI("#{referer_host}#{endpoint}")
  end

  # Define default URL options to not include locale
  def default_url_options(_options = {})
    {}
  end
end
