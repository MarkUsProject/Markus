# frozen_string_literal: true

# Writes a fetched Jupyter file into the student's MarkUs repository using the
# same helper methods used by the normal MarkUs web submission flow.
class JupyterSubmissionWriter
  include RepositoryHelper

  class WriteError < StandardError
  end

  def initialize(assignment:, grouping:, current_role:, current_user:, destination_path:, filename:, content:,
                 content_type:)
    @assignment = assignment
    @grouping = grouping
    @current_role = current_role
    @current_user = current_user
    @destination_path = destination_path.to_s
    @filename = filename.to_s
    @content = content.to_s
    @content_type = content_type.presence || 'application/octet-stream'
  end

  def write!
    validate_destination_path!

    path_inside_assignment = File.dirname(@destination_path)
    path_inside_assignment = '' if path_inside_assignment == '.'

    repo_path = FileHelper.checked_join(@assignment.repository_folder, path_inside_assignment)
    raise WriteError, I18n.t('errors.invalid_path') if repo_path.nil?

    path = Pathname.new(repo_path)
    revision_identifier = nil

    @grouping.access_repo do |repo|
      txn = repo.get_transaction(@current_user.user_name)
      uploaded_file = build_uploaded_file

      required_files = if @current_role.student? && @assignment.only_required_files
                         @assignment.assignment_files.pluck(:filename).map do |name|
                           File.join(@assignment.repository_folder, name)
                         end
                       end

      success, messages = add_file(
        uploaded_file,
        @current_role,
        repo,
        path: path,
        txn: txn,
        check_size: true,
        required_files: required_files
      )

      raise WriteError, messages.join(', ') unless success

      commit_success, commit_message = commit_transaction(repo, txn)
      raise WriteError, commit_message unless commit_success

      revision_identifier = repo.get_latest_revision.revision_identifier.to_s
    ensure
      uploaded_file&.tempfile&.close!
    end

    revision_identifier
  rescue StandardError => e
    raise e if e.is_a?(WriteError)

    raise WriteError, e.message
  end

  private

  def validate_destination_path!
    raise WriteError, 'Destination path is missing.' if @destination_path.blank?

    cleaned = Pathname.new(@destination_path).cleanpath.to_s
    if cleaned.start_with?('../') || cleaned == '..' || cleaned.start_with?('/')
      raise WriteError, 'Invalid destination path.'
    end

    @destination_path = cleaned
    @filename = File.basename(cleaned)
    raise WriteError, 'Destination filename is missing.' if @filename.blank?
  end

  def build_uploaded_file
    sanitized_filename = FileHelper.sanitize_file_name(@filename)
    tempfile = Tempfile.new(['jupyter_submission', File.extname(sanitized_filename)])
    tempfile.binmode
    tempfile.write(@content)
    tempfile.rewind

    ActionDispatch::Http::UploadedFile.new(
      filename: sanitized_filename,
      tempfile: tempfile,
      type: @content_type
    )
  end
end
