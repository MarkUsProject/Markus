class AnnotationCategoriesController < ApplicationController
  respond_to :js

  before_action { authorize! }

  layout 'assignment_content'

  responders :flash

  def index
    @assignment = Assignment.find(params[:assignment_id])
    @annotation_categories = AnnotationCategory.visible_categories(@assignment, current_role)
                                               .includes(:assignment, :annotation_texts)
    respond_to do |format|
      format.html
      format.json do
        data = AnnotationCategory.to_json(@annotation_categories)
        render json: data
      end
    end
  end

  def new
    @assignment = Assignment.find(params[:assignment_id])
  end

  def create
    @assignment = Assignment.find(params[:assignment_id])
    @annotation_category = @assignment.annotation_categories.new(annotation_category_params)
    if @annotation_category.save
      flash_message(:success, t('.success'))
      respond_to do |format|
        format.js { render :insert_new_annotation_category }
      end
    else
      respond_with @annotation_category do |format|
        format.js { head :bad_request }
      end
    end
  end

  def show
    @annotation_category = record
    @assignment = @annotation_category.assignment
    @annotation_texts = annotation_text_data(record)
  end

  def destroy
    @annotation_category = record
    @assignment = @annotation_category.assignment
    if @annotation_category.destroy
      flash_message(:success, t('.success'))
    else
      flash_message(:error, t('.error'))
      render 'show', assignment_id: @assignment.id, id: @annotation_category.id
    end
  end

  def update
    @annotation_category = record
    @assignment = @annotation_category.assignment
    if @annotation_category.update(annotation_category_params)
      flash_message(:success, t('.success'))
      @annotation_texts = annotation_text_data(record)
    else
      respond_with @annotation_category, render: { body: nil, status: :bad_request }
    end
  end

  def new_annotation_text
    @assignment = Assignment.find(params[:assignment_id])
    @annotation_category = @assignment.annotation_categories.find(params[:annotation_category_id])
  end

  def create_annotation_text
    @annotation_text = AnnotationText.new(
      **annotation_text_params.to_h.symbolize_keys,
      creator_id: current_role.id,
      last_editor_id: current_role.id
    )

    if @annotation_text.save
      flash_now(:success, t('annotation_categories.update.success'))
      @annotation_category = @annotation_text.annotation_category
      @assignment = @annotation_category.assignment
      @text = annotation_text_data(@annotation_category).find do |text|
        text[:id] == @annotation_text.id
      end
      render :insert_new_annotation_text
    else
      flash_message(:error, t('.error'))
      head :bad_request
    end
  end

  def destroy_annotation_text
    @annotation_text = record
    @assignment = Assignment.find_by(id: params[:assignment_id])
    if @annotation_text.destroy
      flash_now(:success, t('.success'))
    else
      flash_message(:error, t('.deductive_annotation_released_error'))
      head :bad_request
    end
  end

  def update_annotation_text
    @annotation_text = record
    @assignment = Assignment.find_by(id: params[:assignment_id])
    if @annotation_text.update(**annotation_text_params.to_h.symbolize_keys, last_editor_id: current_role.id)
      flash_now(:success, t('annotation_categories.update.success'))
      @text = annotation_text_data(@annotation_text.annotation_category, course: record.course).find do |text|
        text[:id] == @annotation_text.id
      end
    else
      flash_message(:error, t('.deductive_annotation_released_error'))
      head :bad_request
    end
  end

  def find_annotation_text
    string = params[:string]

    texts_for_current_assignment = AnnotationText.joins(:annotation_category)
                                                 .where('annotation_categories.assessment_id': params[:assignment_id])
    one_time_texts = AnnotationText.joins(annotations: { result: { grouping: :group } })
                                   .where(
                                     creator_id: current_role.id,
                                     'groupings.assessment_id': params[:assignment_id],
                                     annotation_category_id: nil
                                   )

    annotation_texts = texts_for_current_assignment
                       .where('lower(content) LIKE ?', "#{ApplicationRecord.sanitize_sql_like(string.downcase)}%")
                       .limit(10) |
                       one_time_texts.where('lower(content) LIKE ?',
                                            "#{ApplicationRecord.sanitize_sql_like(string.downcase)}%").limit(10)
    render json: annotation_texts
  end

  # This method handles the drag/drop Annotations sorting.
  # It currently ignores annotation categories that are not associated with the passed assignment.
  def update_positions
    assignment = Assignment.find(params[:assignment_id])
    position = 0

    params[:annotation_category].compact.each do |id|
      annotation_category = assignment.annotation_categories.find_by(id: id)
      next if annotation_category.nil?

      annotation_category.update(position: position)
      position += 1
    end

    head :ok
  end

  def download
    @assignment = Assignment.find(params[:assignment_id])
    @annotation_categories = @assignment.annotation_categories
    case params[:format]
    when 'csv'
      file_out = AnnotationCategory.to_csv(@annotation_categories)
      send_data file_out,
                filename: "#{@assignment.short_identifier}_annotations.csv",
                disposition: 'attachment'
    when 'yml'
      send_data AnnotationCategory.annotation_categories_to_yml(@annotation_categories),
                filename: "#{@assignment.short_identifier}_annotations.yml",
                disposition: 'attachment'
    else
      flash[:error] = t('download_errors.unrecognized_format',
                        format: params[:format])
      redirect_to action: 'index',
                  id: params[:id]
    end
  end

  def upload
    @assignment = Assignment.find(params[:assignment_id])
    begin
      data = process_file_upload
    rescue Psych::SyntaxError => e
      flash_message(:error, t('upload_errors.syntax_error', error: e.to_s))
    rescue StandardError => e
      flash_message(:error, e.message)
    else
      AnnotationCategory.transaction do
        if data[:type] == '.csv'
          result = MarkusCsv.parse(data[:contents], encoding: data[:encoding]) do |row|
            next if CSV.generate_line(row).strip.empty?
            AnnotationCategory.add_by_row(row, @assignment, current_role)
          end
          if result[:invalid_lines].empty?
            flash_message(:success, result[:valid_lines]) unless result[:valid_lines].empty?
          else
            flash_message(:error, result[:invalid_lines])
            raise ActiveRecord::Rollback
          end
        elsif data[:type] == '.yml'
          begin
            successes = AnnotationCategory.upload_annotations_from_yaml(data[:contents], @assignment, current_role)
            if successes > 0
              flash_message(:success, t('annotation_categories.upload.success',
                                        annotation_category_number: successes))
            end
          rescue CsvInvalidLineError => e
            flash_message(:error, e.message)
            raise ActiveRecord::Rollback
          end
        end
      end
    end
    redirect_to course_assignment_annotation_categories_path(current_course, @assignment)
  end

  def annotation_text_data(category, course: nil)
    shared_values = ['annotation_texts.id AS id',
                     'users_roles.user_name AS last_editor',
                     'users.user_name AS creator',
                     'annotation_texts.content AS content']
    course ||= category&.course
    base_query = AnnotationText.joins(creator: :user)
                               .left_outer_joins(last_editor: :user)
                               .where('annotation_texts.annotation_category_id': category)
                               .where('roles.course_id': course)
                               .order('users.user_name')
    if category.nil?
      text_data = base_query.joins(annotations: { result: { grouping: :group } })
                            .where('groupings.assessment_id': params[:assignment_id])
                            .order('results.id')
                            .pluck_to_hash('groups.group_name AS group_name',
                                           'groupings.assessment_id AS assignment_id',
                                           'results.id AS result_id',
                                           'results.submission_id AS submission_id',
                                           *shared_values)
    else
      text_data = base_query.left_outer_joins(annotation_category: :flexible_criterion)
                            .pluck_to_hash('annotation_categories.assessment_id AS assignment_id',
                                           'annotation_texts.deduction AS deduction',
                                           'annotation_texts.annotation_category_id AS annotation_category',
                                           'criteria.max_mark AS max_mark',
                                           *shared_values)
      text_usage = AnnotationText.left_outer_joins(annotations: :result)
                                 .where('annotation_texts.annotation_category_id': category)
                                 .group('annotation_texts.id')
                                 .count('annotations.id')
      text_released = AnnotationText.left_outer_joins(annotations: :result)
                                    .where('annotation_texts.annotation_category_id': category)
                                    .group('annotation_texts.id')
                                    .count('results.released_to_students OR NULL')
      text_data.each do |text|
        text['num_uses'] = text_usage[text[:id]]
        text['released'] = text_released[text[:id]]
      end
    end
    text_data
  end

  def annotation_text_uses
    render json: record.uses
  end

  def uncategorized_annotations
    @assignment = Assignment.find(params[:assignment_id])
    @texts = annotation_text_data(nil, course: @assignment.course)
    respond_to do |format|
      format.js
      format.json { render json: @texts }
      format.csv do
        data = MarkusCsv.generate(
          @texts
        ) do |text|
          row = [text[:group_name], text[:last_editor], text[:creator], text[:content]]
          row
        end
        filename = "#{@assignment.short_identifier}_one_time_annotations.csv"
        send_data data,
                  disposition: 'attachment',
                  type: 'text/csv',
                  filename: filename
      end
    end
  end

  private

  def annotation_category_params
    params.require(:annotation_category)
          .permit(:annotation_category_name, :flexible_criterion_id)
  end

  def annotation_text_params
    params.permit(:id, :content, :deduction, :annotation_category_id)
  end

  # This override is necessary because this controller is acting as a controller
  # for both annotation categories and annotation texts.
  #
  # TODO: move all annotation text routes into their own controller and remove this
  def record
    @record ||= if params[:annotation_category_id]
                  AnnotationText.find_by(id: params[:id])
                elsif params[:annotation_text_id]
                  AnnotationText.find_by(id: params[:annotation_text_id])
                else
                  AnnotationCategory.find_by(id: params[:id])
                end
  end

  def flash_interpolation_options
    { errors: @annotation_category.errors.full_messages.join('; ') }
  end
end
