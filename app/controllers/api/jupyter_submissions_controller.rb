# frozen_string_literal: true

require 'json'

module Api
  class JupyterSubmissionsController < ApplicationController
    include SubmissionsHelper

    # Local prototype only.
    # For production, replace these skips with proper MarkUs/JupyterHub authorization.
    skip_before_action :verify_authenticity_token, only: [:create], raise: false
    skip_verify_authorized only: :create

    def create
      payload = request.request_parameters.presence || params.to_unsafe_h

      jupyter_info = payload['jupyter'] || {}
      notebook_path = payload['notebook_path']

      destination_path = sanitize_destination_path(
        payload['destination_path'].presence ||
          payload['notebook_name'].presence ||
          File.basename(notebook_path.to_s)
      )

      assignment = find_assignment_from_payload!(payload)

      # Intended production flow:
      # Jupyter token -> JupyterHub identity -> MarkUs user -> MarkUs student role.
      #
      # Local standalone JupyterLab testing:
      # Set JUPYTER_DEV_USERNAME in docker-compose.yml.
      student = current_role || find_student_role_from_jupyter_token!(jupyter_info, assignment)

      @jupyter_markus_role = student
      @jupyter_markus_user = role_user!(student)

      grouping = find_or_create_grouping_for_student!(student, assignment)

      notebook = JupyterNotebookFetcher.new(
        origin: jupyter_info['origin'],
        base_url: jupyter_info['base_url'],
        token: jupyter_info['token'],
        notebook_path: notebook_path
      ).fetch

      notebook_content = notebook_content_as_string(notebook[:content])

      # SubmissionsHelper#upload_file expects API-style params:
      # filename, mime_type, and file_content.
      params[:filename] = destination_path
      params[:mime_type] = 'application/x-ipynb+json'
      params[:file_content] = notebook_content

      Rails.logger.info(
        "[JupyterSubmissionsController] Submitting #{destination_path} " \
        "for user=#{@jupyter_markus_user.user_name}, " \
        "assignment_id=#{assignment.id}, grouping_id=#{grouping.id}"
      )

      upload_file(grouping, only_required_files: assignment.only_required_files)

      # upload_file may already render a MarkUs response.
      # Avoid double-rendering if that happened.
      return if performed?

      render json: {
        status: 'success',
        message: 'Notebook submitted to MarkUs.',
        submitted_file: destination_path,
        markus_target: {
          assignment_id: assignment.id,
          assignment: assignment.short_identifier,
          repository_folder: assignment.repository_folder,
          grouping_id: grouping.id,
          group_id: grouping.group_id,
          student_role_id: student.id,
          markus_user_name: @jupyter_markus_user.user_name
        },
        fetched_notebook: {
          name: notebook[:name],
          path: notebook[:path],
          type: notebook[:type],
          format: notebook[:format]
        }
      }, status: :ok
    rescue JupyterIdentityFetcher::IdentityError => e
      return if performed?

      render json: {
        status: 'error',
        message: e.message,
        error_class: e.class.name
      }, status: :unauthorized
    rescue JupyterNotebookFetcher::FetchError => e
      return if performed?

      render json: {
        status: 'error',
        message: e.message,
        error_class: e.class.name
      }, status: :bad_gateway
    rescue ActiveRecord::RecordNotFound, ArgumentError => e
      return if performed?

      render json: {
        status: 'error',
        message: e.message,
        error_class: e.class.name
      }, status: :not_found
    rescue StandardError => e
      Rails.logger.error("[JupyterSubmissionsController] #{e.class}: #{e.message}")
      Rails.logger.error(e.backtrace.join("\n")) if e.backtrace

      return if performed?

      render json: {
        status: 'error',
        message: e.message,
        error_class: e.class.name
      }, status: :internal_server_error
    end

    private

    # These two overrides are important for local prototype mode.
    # MarkUs's upload helper may call current_user/current_role internally.
    def current_user
      return @jupyter_markus_user if @jupyter_markus_user.present?

      super if defined?(super)
    end

    def current_role
      return @jupyter_markus_role if @jupyter_markus_role.present?

      super if defined?(super)
    end

    def find_assignment_from_payload!(payload)
      if payload['assessment_id'].present?
        return Assignment.find(payload['assessment_id'])
      end

      if payload['assignment_id'].present?
        return Assignment.find(payload['assignment_id'])
      end

      assignment_key = payload['assignment'].to_s.strip

      if assignment_key.blank?
        raise ActiveRecord::RecordNotFound,
              'Missing assignment, assignment_id, or assessment_id in notebook metadata.'
      end

      course = find_course_from_payload(payload)
      scope = course ? Assignment.where(course_id: course.id) : Assignment.all

      assignment = if integer_string?(assignment_key)
                     scope.find_by(id: assignment_key)
                   else
                     scope.find_by(short_identifier: assignment_key)
                   end

      if assignment.nil?
        raise ActiveRecord::RecordNotFound,
              "No MarkUs assignment found for #{assignment_key.inspect}."
      end

      assignment
    end

    def find_course_from_payload(payload)
      course_id = payload['course_id']
      return Course.find(course_id) if course_id.present?

      course_key = payload['course'].to_s.strip
      return if course_key.blank?

      return Course.find(course_key) if integer_string?(course_key)

      find_course_by_existing_column(course_key)
    end

    def find_course_by_existing_column(course_key)
      possible_columns = %w[name display_name short_identifier]

      possible_columns.each do |column|
        next unless Course.column_names.include?(column)

        course = Course.find_by(column => course_key)
        return course if course
      end

      nil
    end

    def find_student_role_from_jupyter_token!(jupyter_info, assignment)
      username = resolve_jupyter_username!(jupyter_info)

      Rails.logger.info(
        "[JupyterSubmissionsController] Jupyter token resolved to username=#{username}"
      )

      user = User.find_by(user_name: username)

      if user.nil?
        raise ActiveRecord::RecordNotFound,
              "No MarkUs user found with user_name=#{username.inspect}."
      end

      role = find_role_for_user_and_course(user, assignment.course_id)

      if role.nil?
        raise ActiveRecord::RecordNotFound,
              "No student role found for Jupyter/MarkUs username #{username.inspect} " \
              "in course_id=#{assignment.course_id}."
      end

      role
    end

    def resolve_jupyter_username!(jupyter_info)
      # Local development fallback only.
      # This is useful when testing with standalone JupyterLab, where the token
      # authenticates the server but does not identify a real JupyterHub user.
      if Rails.env.development? && ENV['JUPYTER_DEV_USERNAME'].present?
        return ENV.fetch('JUPYTER_DEV_USERNAME', nil)
      end

      JupyterIdentityFetcher.new(
        origin: jupyter_info['origin'],
        base_url: jupyter_info['base_url'],
        token: jupyter_info['token']
      ).username
    end

    def find_role_for_user_and_course(user, course_id)
      if user.respond_to?(:roles)
        role = user.roles.find_by(course_id: course_id)
        return role if role
      end

      if defined?(Student)
        role = Student.find_by(user_id: user.id, course_id: course_id)
        return role if role
      end

      if defined?(Role)
        role = Role.find_by(user_id: user.id, course_id: course_id)
        return role if role
      end

      nil
    end

    def role_user!(role)
      user = role_user(role)

      if user.nil?
        raise ActiveRecord::RecordNotFound,
              "Could not resolve a MarkUs User for role id=#{role&.id.inspect}."
      end

      user
    end

    def role_user(role)
      return role.user if role.respond_to?(:user) && role.user.present?

      if role.respond_to?(:user_id) && role.user_id.present?
        user = User.find_by(id: role.user_id)
        return user if user
      end

      nil
    end

    def find_or_create_grouping_for_student!(student, assignment)
      if student.respond_to?(:has_accepted_grouping_for?) &&
         student.has_accepted_grouping_for?(assignment.id)
        return student.accepted_grouping_for(assignment.id)
      end

      if assignment.group_max == 1
        student.create_group_for_working_alone_student(assignment.id)
        grouping = student.accepted_grouping_for(assignment.id)
        return grouping if grouping
      end

      if student.respond_to?(:create_autogenerated_name_group)
        grouping = student.create_autogenerated_name_group(assignment)
        return grouping if grouping
      end

      raise ActiveRecord::RecordNotFound,
            'Could not find or create a grouping for this student and assignment.'
    end

    def notebook_content_as_string(content)
      case content
      when String
        content
      when Hash, Array
        JSON.pretty_generate(content)
      else
        content.to_json
      end
    end

    def sanitize_destination_path(path)
      filename = File.basename(path.to_s.strip)

      raise ArgumentError, 'Destination filename is missing.' if filename.blank?

      unless filename.end_with?('.ipynb')
        raise ArgumentError, 'Only .ipynb notebook submissions are currently supported.'
      end

      filename
    end

    # SubmissionsHelper#upload_file expects this helper method to exist.
    # MainApiController has it, but this controller inherits from ApplicationController
    # to avoid the MarkUs API permission layer for the local prototype.
    def has_missing_params?(required_params)
      required_params.any? { |param| params[param].blank? }
    end

    def integer_string?(value)
      value.to_s.match?(/\A\d+\z/)
    end
  end
end
