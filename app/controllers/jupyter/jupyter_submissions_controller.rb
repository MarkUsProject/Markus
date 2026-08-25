module Jupyter
  class JupyterSubmissionsController < ApplicationController
    include RepositoryHelper

    class IdentityError < StandardError; end
    class FetchError < StandardError; end
    class BadRequestError < StandardError; end
    class ForbiddenError < StandardError; end
    class SubmissionError < StandardError; end

    ERROR_STATUSES = {
      ActiveRecord::RecordNotFound => :not_found,
      ActionController::ParameterMissing => :bad_request,
      ArgumentError => :bad_request,
      BadRequestError => :bad_request,
      ForbiddenError => :forbidden,
      IdentityError => :unauthorized,
      FetchError => :bad_gateway,
      SubmissionError => :unprocessable_content
    }.freeze

    RESPONSE_BODY_TRUNCATE_LENGTH = 500
    JUPYTER_SESSION_TTL = 15.minutes

    # codeql[rb/csrf-protection-disabled] -- authenticated via header token, not cookies, so CSRF does not apply
    skip_before_action :verify_authenticity_token, only: [:create_session, :submit], raise: false

    # The Jupyter endpoints resolve the submitting user separately, so they
    # do not require an existing MarkUs browser session.
    skip_before_action :authenticate, only: [:create_session, :submit]
    skip_before_action :check_record, only: [:create_session, :submit]
    skip_before_action :check_course_switch, only: [:create_session, :submit]

    skip_verify_authorized only: [:create_session, :submit]

    before_action :ensure_jupyter_enabled!
    before_action :authenticate_jupyter_session!, only: [:submit]

    # Verifies the caller's JupyterHub token and mints a short-lived signed session token.
    def create_session
      jupyter_info = create_session_params[:jupyter]
      origin, = parse_jupyter_base_url!(jupyter_info[:base_url])
      token = jupyter_info[:token]

      user_name = find_username_from_jupyter_token!(origin, token)
      session_token, expires_at = encode_jupyter_session(user_name: user_name, origin: origin, token: token)

      render json: {
        status: 'success',
        session_token: session_token,
        expires_at: expires_at.iso8601,
        markus_user_name: user_name
      }
    rescue StandardError => e
      render_error(e)
    end

    def submit
      payload = submit_params

      jupyter_path = payload[:notebook_path].to_s
      destination_path = File.basename(jupyter_path)
      if destination_path.blank?
        raise ArgumentError, I18n.t('jupyter.submit.missing_destination_filename')
      end

      course = find_course_from_payload!(payload)

      student = course.students.find_by(user_id: current_user.id)

      if student.nil?
        raise ForbiddenError,
              I18n.t('jupyter.submit.not_a_student', user_name: current_user.user_name, course_name: course.name)
      end

      assignment = find_assignment_from_payload!(payload, student)

      unless assignment.api_submit
        raise ForbiddenError, I18n.t('submissions.api_submission_disabled')
      end

      jupyter_file = fetch_jupyter_file!(@jupyter_origin, @jupyter_base_path, @jupyter_token, jupyter_path)

      submit_jupyter_file!(
        assignment: assignment,
        student: student,
        path: destination_path,
        jupyter_file: jupyter_file
      )

      render json: {
        status: 'success',
        message: I18n.t('flash.actions.update_files.success'),
        submitted_file: destination_path,
        markus_target: {
          course_id: course.id,
          course: course.name,
          assignment_id: assignment.id,
          assignment: assignment.short_identifier,
          markus_user_name: current_user.user_name
        }
      }
    rescue StandardError => e
      render_error(e)
    end

    private

    def render_error(e)
      status = ERROR_STATUSES.find { |error_class, _| e.is_a?(error_class) }&.last
      if status.nil?
        Rails.logger.error("Jupyter submission failed: #{e.class}: #{e.message}\n#{e.backtrace&.join("\n")}")
        render json: {
          status: 'error',
          message: I18n.t('jupyter.submit.internal_error'),
          error_class: 'InternalServerError'
        }, status: :internal_server_error
      else
        render json: {
          status: 'error',
          message: e.message,
          error_class: e.class.name
        }, status: status
      end
    end

    def ensure_jupyter_enabled!
      return if Settings.jupyter.enabled

      render json: {
        status: 'error',
        message: I18n.t('jupyter.feature_disabled')
      }, status: :service_unavailable
    end

    # Resolves +current_user+ (via +@real_user+, mirroring Api::MainApiController#authenticate)
    # from a previously-issued session token, without touching the MarkUs session cookie.
    # Stashes the parsed Jupyter origin/base_path/token as ivars so +submit+ doesn't need to
    # re-parse +jupyter.base_url+.
    def authenticate_jupyter_session!
      params.require(:jupyter).require([:base_url, :token])
      jupyter_info = params.require(:jupyter).permit(:base_url, :token)
      session_token = params[:session_token]

      if session_token.blank?
        raise IdentityError, I18n.t('jupyter.submit.missing_session_token')
      end

      origin, base_path = parse_jupyter_base_url!(jupyter_info[:base_url])
      @jupyter_origin = origin
      @jupyter_base_path = base_path
      @jupyter_token = jupyter_info[:token]
      @real_user = decode_jupyter_session!(session_token, origin: origin, token: @jupyter_token)
    rescue StandardError => e
      render_error(e)
    end

    def create_session_params
      params.require(:jupyter).require([:base_url, :token])

      params.permit(jupyter: [:base_url, :token])
    end

    def submit_params
      params.require(:notebook_path)

      params.permit(:notebook_path, :session_token, :course_id, :course, :assignment_id, :assignment,
                    jupyter: [:base_url, :token])
    end

    # +base_url+ is an absolute URL (e.g. "http://localhost:8888/user/foo/"). Splits it into
    # a trusted origin (validated against Settings.jupyter_server.hosts) and a normalized path,
    # rather than trusting a separate client-supplied "origin" field that could disagree with it.
    def parse_jupyter_base_url!(base_url)
      uri = URI.parse(base_url.to_s.strip)

      unless uri.is_a?(URI::HTTP) && uri.host.present?
        raise BadRequestError, I18n.t('jupyter.submit.invalid_base_url', base_url: base_url)
      end

      scheme = uri.scheme.downcase
      host = uri.host.downcase
      origin = if uri.port == uri.default_port
                 "#{scheme}://#{host}"
               else
                 "#{scheme}://#{host}:#{uri.port}"
               end

      allowed_hosts = Settings.jupyter_server.hosts.map { |h| h.strip.sub(%r{/*\z}, '').downcase }
      unless allowed_hosts.include?(origin)
        raise BadRequestError, I18n.t('jupyter.submit.origin_not_allowed', origin: origin)
      end

      path = uri.path.presence || '/'
      path = "/#{path}" unless path.start_with?('/')
      path = "#{path}/" unless path.end_with?('/')

      if path.split('/').include?('..')
        raise BadRequestError, I18n.t('jupyter.submit.invalid_base_url_path', base_url: base_url)
      end

      [origin, path]
    rescue URI::InvalidURIError => e
      raise BadRequestError, I18n.t('jupyter.submit.unparseable_base_url', error: e.message)
    end

    def find_username_from_jupyter_token!(origin, token)
      uri = URI.parse("#{origin}/hub/api/user")
      model = jupyter_api_get!(uri, token, error_class: IdentityError)
      name = model['name']

      if name.blank?
        raise IdentityError, I18n.t('jupyter.submit.missing_username')
      end

      unless User.exists?(user_name: name)
        raise ActiveRecord::RecordNotFound, I18n.t('jupyter.submit.unknown_user', user_name: name.inspect)
      end

      name
    end

    def encode_jupyter_session(user_name:, origin:, token:)
      expires_at = JUPYTER_SESSION_TTL.from_now
      payload = {
        'user_name' => user_name,
        'origin' => origin,
        'token_hash' => Digest::SHA256.hexdigest(token),
        'expires_at' => expires_at.to_i
      }

      [Rails.application.message_verifier(:jupyter_session).generate(payload), expires_at]
    end

    # Verifies a session token minted by +encode_jupyter_session+. Verifies request
    # params origin and JupyterHub token against the session token.
    def decode_jupyter_session!(session_token, origin:, token:)
      payload = Rails.application.message_verifier(:jupyter_session).verify(session_token)

      if payload['expires_at'].to_i < Time.current.to_i
        raise IdentityError, I18n.t('jupyter.submit.session_expired')
      end

      unless payload['origin'] == origin
        raise IdentityError, I18n.t('jupyter.submit.session_origin_mismatch')
      end

      unless ActiveSupport::SecurityUtils.secure_compare(payload['token_hash'], Digest::SHA256.hexdigest(token))
        raise IdentityError, I18n.t('jupyter.submit.session_token_mismatch')
      end

      user = User.find_by(user_name: payload['user_name'])

      if user.nil?
        raise ActiveRecord::RecordNotFound, I18n.t('jupyter.submit.unknown_user', user_name: payload['user_name'])
      end

      user
    rescue ActiveSupport::MessageVerifier::InvalidSignature
      raise IdentityError, I18n.t('jupyter.submit.invalid_session_token')
    end

    def find_course_from_payload!(payload)
      if payload[:course_id].present?
        course_id = payload[:course_id].to_i
        course = Course.find_by(id: course_id, is_hidden: false)
      elsif payload[:course].present?
        course_name = payload[:course].to_s.strip
        course = Course.find_by(name: course_name, is_hidden: false)
      else
        raise BadRequestError, I18n.t('jupyter.submit.missing_course')
      end

      if course.nil?
        raise ActiveRecord::RecordNotFound, I18n.t('jupyter.submit.course_not_found')
      end

      course
    end

    def find_assignment_from_payload!(payload, student)
      if payload[:assignment_id].present?
        assignment_id = payload[:assignment_id].to_i
        assignment = student.visible_assessments.find_by(id: assignment_id, type: Assignment.name)
      elsif payload[:assignment].present?
        short_identifier = payload[:assignment].to_s.strip
        assignment = student.visible_assessments.find_by(short_identifier: short_identifier, type: Assignment.name)
      else
        raise BadRequestError, I18n.t('jupyter.submit.missing_assignment')
      end

      if assignment.nil?
        raise ActiveRecord::RecordNotFound, I18n.t('jupyter.submit.assignment_not_found')
      end

      assignment
    end

    def fetch_jupyter_file!(origin, base_path, token, jupyter_path)
      uri = contents_uri(origin, base_path, jupyter_path)
      model = jupyter_api_get!(uri, token, error_class: FetchError)

      {
        name: model['name'],
        path: model['path'],
        type: model['type'],
        format: model['format'],
        mimetype: model['mimetype'],
        writable: model['writable'],
        content: model['content']
      }
    rescue URI::InvalidURIError => e
      raise FetchError, I18n.t('jupyter.submit.invalid_jupyter_url', error: e.message)
    end

    def jupyter_api_get!(uri, token, error_class:)
      request = Net::HTTP::Get.new(uri)
      request['Accept'] = 'application/json'
      request['Authorization'] = "token #{token}"

      response = Net::HTTP.start(
        uri.hostname,
        uri.port,
        use_ssl: uri.scheme == 'https',
        open_timeout: 10,
        read_timeout: 30
      ) do |http|
        http.request(request)
      end

      unless response.is_a?(Net::HTTPSuccess)
        raise error_class,
              I18n.t('jupyter.submit.request_failed', uri: uri, code: response.code,
                                                      body: truncate_response_body(response.body))
      end

      JSON.parse(response.body)
    rescue JSON::ParserError => e
      raise error_class, I18n.t('jupyter.submit.invalid_json_response', uri: uri, error: e.message)
    rescue Errno::ECONNREFUSED, SocketError, Net::OpenTimeout, Net::ReadTimeout, OpenSSL::SSL::SSLError => e
      raise error_class, I18n.t('jupyter.submit.connection_failed', uri: uri, error: e.message)
    end

    # Truncates a Jupyter/JupyterHub error response body before it is embedded in a message
    # returned to the client, since these can be arbitrarily large (e.g. an HTML error page).
    def truncate_response_body(body)
      body.to_s.truncate(RESPONSE_BODY_TRUNCATE_LENGTH)
    end

    def contents_uri(origin, base_path, jupyter_path)
      encoded_path = jupyter_path
                    .split('/')
                    .compact_blank
                    .map { |part| ERB::Util.url_encode(part) }
                    .join('/')

      uri = URI.parse("#{origin}#{base_path}api/contents/#{encoded_path}")
      uri.query = URI.encode_www_form(content: '1')
      uri
    end

    def submit_jupyter_file!(assignment:, student:, path:, jupyter_file:)
      grouping =
        if student.has_accepted_grouping_for?(assignment.id)
          student.accepted_grouping_for(assignment.id)
        elsif assignment.group_max == 1
          student.create_group_for_working_alone_student(assignment.id)
          student.accepted_grouping_for(assignment.id)
        else
          student.create_autogenerated_name_group(assignment)
        end

      content = jupyter_file[:content]
      content = JSON.generate(content) if jupyter_file[:format] == 'json'

      required_files =
        if assignment.only_required_files
          assignment.assignment_files.pluck(:filename)
        end

      # add_file only ever calls #read/#rewind/#size/#original_filename/#content_type on this,
      # so a StringIO stands in for the Tempfile UploadedFile normally wraps.
      uploaded_file = ActionDispatch::Http::UploadedFile.new(
        tempfile: StringIO.new(content),
        filename: path,
        type: 'application/x-ipynb+json'
      )

      success, messages = grouping.access_repo do |repo|
        add_file(
          uploaded_file,
          student,
          repo,
          path: assignment.repository_folder,
          required_files: required_files
        )
      end

      return if success

      formatted_messages =
        Array(messages)
          .map { |msg, other_info| repository_message_text(msg, other_info, assignment.course) }
          .compact_blank
          .join(', ')

      raise SubmissionError, formatted_messages
    end
  end
end
