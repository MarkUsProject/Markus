class AnnotationsController < ApplicationController
  before_action { authorize! }

  def add_existing_annotation
    result = Result.find(params[:result_id])
    submission = result.submission
    submission_file = submission.submission_files.find(params[:submission_file_id])
    rmd_convert = submission_file.is_rmd? && Rails.application.config.rmd_convert_enabled

    base_attributes = {
      submission_file_id: submission_file.id,
      is_remark: submission.has_remark?,
      annotation_text_id: params[:annotation_text_id],
      annotation_number: result.annotations.size + 1,
      creator: current_role,
      result_id: params[:result_id]
    }

    if submission_file.is_supported_image?
      @annotation = result.annotations.create(
        type: 'ImageAnnotation',
        x1: params[:x1],
        y1: params[:y1],
        x2: params[:x2],
        y2: params[:y2],
        **base_attributes
      )
    elsif submission_file.is_pdf?
      @annotation = result.annotations.create(
        type: 'PdfAnnotation',
        x1: params[:x1],
        y1: params[:y1],
        x2: params[:x2],
        y2: params[:y2],
        page: params[:page],
        **base_attributes
      )
    elsif submission_file.is_pynb? || rmd_convert
      @annotation = result.annotations.create!(
        type: 'HtmlAnnotation',
        start_node: params[:start_node],
        start_offset: params[:start_offset],
        end_node: params[:end_node],
        end_offset: params[:end_offset],
        **base_attributes
      )
    else
      @annotation = result.annotations.create(
        type: 'TextAnnotation',
        line_start: params[:line_start],
        line_end: params[:line_end],
        column_start: params[:column_start],
        column_end: params[:column_end],
        **base_attributes
      )
    end
    render :create
  end

  def create
    result = Result.find(params[:result_id])
    submission = result.submission
    submission_file = submission.submission_files.find(params[:submission_file_id])
    rmd_convert = submission_file.is_rmd? && Rails.application.config.rmd_convert_enabled

    d = result.grouping.assignment.annotation_categories.find_by(id: params[:category_id])&.flexible_criterion_id

    if params[:annotation_text_id].present? && params[:category_id].present?
      text = AnnotationText.find(params[:annotation_text_id])
      unless text.annotation_category_id == params[:category_id].to_i
        text.update!(
          annotation_category_id: params[:category_id],
          last_editor_id: current_role.id
        )
      end
    else
      text = AnnotationText.create!(
        content: params[:content],
        annotation_category_id: params[:category_id],
        creator_id: current_role.id,
        last_editor_id: current_role.id,
        deduction: d.nil? ? nil : 0.0
      )
    end

    base_attributes = {
      annotation_number: result.annotations.size + 1,
      annotation_text_id: text.id,
      creator: current_role,
      is_remark: !result.remark_request_submitted_at.nil?,
      submission_file_id: submission_file.id
    }
    if submission_file.is_supported_image?
      @annotation = result.annotations.create!(
        type: 'ImageAnnotation',
        x1: params[:x1],
        x2: params[:x2],
        y1: params[:y1],
        y2: params[:y2],
        **base_attributes
      )
    elsif submission_file.is_pdf?
      @annotation = result.annotations.create!(
        type: 'PdfAnnotation',
        x1: params[:x1],
        x2: params[:x2],
        y1: params[:y1],
        y2: params[:y2],
        page: params[:page],
        **base_attributes
      )
    elsif submission_file.is_pynb? || rmd_convert
      @annotation = result.annotations.create!(
        type: 'HtmlAnnotation',
        start_node: params[:start_node],
        start_offset: params[:start_offset],
        end_node: params[:end_node],
        end_offset: params[:end_offset],
        **base_attributes
      )
    else
      @annotation = result.annotations.create!(
        type: 'TextAnnotation',
        line_start: params[:line_start],
        line_end: params[:line_end],
        column_start: params[:column_start],
        column_end: params[:column_end],
        **base_attributes
      )
    end
  end

  def destroy
    @annotation = record
    result = @annotation.result
    unless @annotation.annotation_text.deduction.nil? || !current_role.ta?
      assignment = result.grouping.assignment
      if assignment.assign_graders_to_criteria &&
          current_role.criterion_ta_associations
                      .pluck(:criterion_id)
                      .exclude?(@annotation.annotation_text.annotation_category.flexible_criterion_id)
        flash_message(:error, t('annotations.prevent_ta_delete'))
        head :bad_request
        return
      end
    end
    text = @annotation.annotation_text
    text.destroy if text.annotation_category_id.nil?
    @annotation.destroy
    result.annotations.reload.each do |annot|
      if annot.annotation_number > @annotation.annotation_number
        annot.update(annotation_number: annot.annotation_number - 1)
      end
    end
  end

  def update
    @annotation = record
    @annotation_text = @annotation.annotation_text
    if !@annotation_text.deduction.nil? && (current_role.ta? || @annotation_text.annotations.joins(:result)
                                             .exists?('results.released_to_students' => true))
      flash_message(:error, t('annotations.prevent_update'))
      head :bad_request
      return
    end

    change_all = !params[:annotation_text] || !params[:annotation_text][:change_all] ||
        params[:annotation_text][:change_all] == '1'
    if change_all
      @annotation_text.update(content: params[:content])
    else
      ActiveRecord::Base.transaction do
        new_text = AnnotationText.create(
          content: params[:content],
          annotation_category_id: nil,
          deduction: nil,
          creator_id: current_role.id,
          last_editor_id: current_role.id
        )
        @annotation.update(annotation_text: new_text)
      end
    end
  end

  protected

  def identification_params
    params.permit(:id, :result_id)
  end
end
