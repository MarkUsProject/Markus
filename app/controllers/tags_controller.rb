class TagsController < ApplicationController
  before_action { authorize! }
  responders :flash

  layout 'assignment_content'

  def index
    @assignment = Assignment.find_by(id: params[:assignment_id])

    respond_to do |format|
      format.html
      format.json do
        parent = @assignment || current_course
        tags = parent.tags.includes(:role, :groupings).order(:name)

        tag_info = tags.map do |tag|
          {
            id: tag.id,
            name: tag.name,
            description: tag.description,
            creator: tag.role.display_name,
            use: tag.groupings.size
          }
        end

        render json: tag_info
      end
    end
  end

  def edit
    @tag = record
  end

  # Creates a new instance of the tag.
  def create
    tag_params = params.require(:tag).permit(:name, :description)
    new_tag = Tag.new(tag_params.merge(role: current_role, assessment: Assessment.find_by(id: params[:assignment_id])))

    if new_tag.save && params[:grouping_id]
      grouping = Grouping.find(params[:grouping_id])
      grouping.tags << new_tag
    end

    respond_with new_tag, location: -> { request.headers['Referer'] || root_path }
  end

  def update
    tag = record
    tag.update(params.require(:tag).permit(:name, :description))

    respond_with tag, location: -> { request.headers['Referer'] || root_path }
  end

  def destroy
    record.destroy
    head :ok
  end

  # Dialog to edit a tag.
  def edit_tag_dialog
    @tag = record

    render partial: 'tags/edit_dialog', handlers: [:erb]
  end

  ###  Upload/Download Methods  ###

  def download
    parent = Assignment.find_by(id: params[:assignment_id]) || current_course
    tags = parent.tags.includes(role: :user).order(:name).pluck(:name, :description, 'users.user_name')

    case params[:format]
    when 'csv'
      output = MarkusCsv.generate(tags) do |tag_data|
        tag_data
      end
      format = 'text/csv'
    else
      # Default to yml download.
      output = tags.map do |name, description, user_name|
        {
          name: name,
          description: description,
          user: user_name
        }
      end.to_yaml
      format = 'text/yml'
    end

    send_data output,
              type: format,
              filename: "tag_list.#{params[:format]}",
              disposition: 'attachment'
  end

  def upload
    assignment = Assignment.find_by(id: params[:assignment_id])
    begin
      data = process_file_upload
    rescue Psych::SyntaxError => e
      flash_message(:error, t('upload_errors.syntax_error', error: e.to_s))
    rescue StandardError => e
      flash_message(:error, e.message)
    else
      if data[:type] == '.csv'
        result = Tag.from_csv(data[:file].read, current_course, assignment&.id)
        flash_message(:error, result[:invalid_lines]) unless result[:invalid_lines].empty?
        flash_message(:success, result[:valid_lines]) unless result[:valid_lines].empty?
      elsif data[:type] == '.yml'
        result = Tag.from_yml(data[:contents], current_course, assignment&.id)
        if result.is_a?(StandardError)
          flash_message(:error, result.message)
        end
      end
    end
    redirect_to course_tags_path(current_course, assignment_id: assignment&.id)
  end

  private

  # Include assignment_id param in parent_params so that check_record can ensure that
  # the assignment is in the same course as the current course
  def parent_params
    params[:assignment_id].nil? ? super : [*super, :assignment_id]
  end
end
