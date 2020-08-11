class AnnotationCategoriesController < ApplicationController
  include AnnotationCategoriesHelper

  respond_to :js

  before_action      :authorize_only_for_admin, except: :index
  before_action      :authorize_for_ta_and_admin, only: :index

  layout 'assignment_content'

  responders :flash

  def index
    @assignment = Assignment.find(params[:assignment_id])
    @annotation_categories = @assignment.annotation_categories.order(:position)
                                        .includes(:assignment, :annotation_texts)
    respond_to do |format|
      format.html
      format.json {
        data = @annotation_categories.map do |cat|
          {
            id: cat.id,
            annotation_category_name: "#{cat.annotation_category_name}"\
                                      "#{cat.flexible_criterion_id.nil? ? '' : " [#{cat.flexible_criterion.name}]"}",
            texts: cat.annotation_texts.map do |text|
              {
                id: text.id,
                content: text.content,
                deduction: text.deduction
              }
            end
          }
        end
        render json: data
      }
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
    @assignment = Assignment.find(params[:assignment_id])
    @annotation_category = AnnotationCategory.find(params[:id])
    @annotation_texts = annotation_text_data(params[:id])
  end

  def destroy
    @assignment = Assignment.find(params[:assignment_id])
    @annotation_category = @assignment.annotation_categories.find(params[:id])
    if @annotation_category.destroy
      flash_message(:success, t('.success'))
    else
      flash_message(:error, t('.error'))
      render 'show', assignment_id: @assignment.id, id: @annotation_category.id
    end
  end

  def update
    @assignment = Assignment.find(params[:assignment_id])
    @annotation_category = @assignment.annotation_categories.find(params[:id])

    if @annotation_category.update(annotation_category_params)
      flash_message(:success, t('.success'))
      render 'show', assignment_id: @assignment.id, id: @annotation_category.id
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
      creator_id: current_user.id,
      last_editor_id: current_user.id
    )

    if @annotation_text.save
      flash_now(:success, t('annotation_categories.update.success'))
      @assignment = Assignment.find(params[:assignment_id])
      @annotation_category = @annotation_text.annotation_category
      @text = annotation_text_data(@annotation_text.annotation_category_id).find do |text|
        text[:id] == @annotation_text.id
      end
      render :insert_new_annotation_text
    else
      flash_message(:error, t('.error'))
      head :bad_request
    end
  end

  def destroy_annotation_text
    @annotation_text = AnnotationText.find(params[:id])
    if @annotation_text.destroy
      flash_now(:success, t('.success'))
    else
      flash_message(:error, t('.deductive_annotation_released_error'))
      head :bad_request
    end
  end

  def update_annotation_text
    @annotation_text = AnnotationText.find(params[:id])
    if @annotation_text.update(**annotation_text_params.to_h.symbolize_keys, last_editor_id: current_user.id)
      flash_now(:success, t('annotation_categories.update.success'))
      @text = annotation_text_data(@annotation_text.annotation_category_id).find do |text|
        text[:id] == @annotation_text.id
      end
    else
      flash_message(:error, t('.deductive_annotation_released_error'))
      head :bad_request
    end
  end

  def find_annotation_text
    @assignment = Assignment.find(params[:assignment_id])
    string = params[:string]
    texts_for_current_assignment = AnnotationText.joins(annotation_category: :assignment)
                                                 .where(assessments: { id: @assignment.id })
    annotation_texts = texts_for_current_assignment.where("content LIKE ?", "#{string}%")
    if annotation_texts.size == 1
      render json: "#{annotation_texts.first.content}".html_safe
    else
      render json: ''.html_safe
    end
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
        ac = prepare_for_conversion(@annotation_categories)
        file_out = MarkusCsv.generate(
          ac) do |annotation_category_name, annotation_texts|
          # csv format is annotation_category.name, annotation_category.flexible_criterion,
          # annotation_text.content[, optional: annotation_text.deduction ]
          annotation_texts.unshift(annotation_category_name)
        end
        send_data file_out,
                  filename: "#{@assignment.short_identifier}_annotations.csv",
                  disposition: 'attachment'
      when 'yml'
        send_data convert_to_yml(@annotation_categories),
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
          result = MarkusCsv.parse(data[:file].read, encoding: data[:encoding]) do |row|
            next if CSV.generate_line(row).strip.empty?
            AnnotationCategory.add_by_row(row, @assignment, current_user)
          end
          if result[:invalid_lines].empty?
            flash_message(:success, result[:valid_lines]) unless result[:valid_lines].empty?
          else
            flash_message(:error, result[:invalid_lines])
            raise ActiveRecord::Rollback
          end
        elsif data[:type] == '.yml'
          successes = 0
          data[:contents].each do |category, category_data|
            if category_data.is_a?(Array)
              AnnotationCategory.add_by_row([category, nil] + category_data, @assignment, current_user)
              successes += 1
            elsif category_data.is_a?(Hash)
              row = [category, category_data['criterion']] + category_data['texts'].flatten
              AnnotationCategory.add_by_row(row, @assignment, current_user)
              successes += 1
            end
          rescue CsvInvalidLineError => e
            flash_message(:error, e.message)
            raise ActiveRecord::Rollback
          end
          if successes > 0
            flash_message(:success, t('annotation_categories.upload.success',
                                      annotation_category_number: successes))
          end
        end
      end
    end
    redirect_to assignment_annotation_categories_path(assignment_id: @assignment.id)
  end

  def annotation_text_data(category)
    shared_values = ['annotation_texts.id AS id',
                     'last_editors_annotation_texts.user_name AS last_editor',
                     'users.user_name AS creator',
                     'annotation_texts.content AS content']
    base_query = AnnotationText.joins(:creator)
                               .left_outer_joins(:last_editor)
                               .where('annotation_texts.annotation_category_id': category)
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
    render json: AnnotationText.find(params[:annotation_text_id]).uses
  end

  def uncategorized_annotations
    @texts = annotation_text_data(nil)
  end

  private

  def annotation_category_params
    params.require(:annotation_category)
          .permit(:annotation_category_name, :flexible_criterion_id)
  end

  def annotation_text_params
    params.permit(:id, :content, :deduction, :annotation_category_id)
  end

  def flash_interpolation_options
    { errors: @annotation_category.errors.full_messages.join('; ') }
  end
end
