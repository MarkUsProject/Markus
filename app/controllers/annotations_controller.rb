class AnnotationsController < ApplicationController

  before_action(except: :add_existing_annotation) do |c|
    c.authorize_for_ta_admin_and_reviewer(params[:assignment_id], params[:result_id])
  end

  before_action :authorize_for_ta_and_admin, only: :add_existing_annotation

  def add_existing_annotation
    result = Result.find(params[:result_id])
    submission = result.submission
    submission_file = submission.submission_files.find(params[:submission_file_id])

    base_attributes = {
      submission_file_id: submission_file.id,
      is_remark: submission.has_remark?,
      annotation_text_id: params[:annotation_text_id],
      annotation_number: result.annotations.size + 1,
      creator: current_user,
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

    @new_num_marked = result.grouping.assignment.get_num_marked(current_user.admin? ? nil : current_user.id)

    render :create
  end

  def new
    @result = Result.find(params[:result_id])
    @assignment = @result.submission.grouping.assignment
  end

  def create
    result = Result.find(params[:result_id])
    submission = result.submission
    submission_file = submission.submission_files.find(params[:submission_file_id])

    text = AnnotationText.create!(
      content: params[:content],
      annotation_category_id: params[:category_id],
      creator_id: current_user.id,
      last_editor_id: current_user.id
    )
    base_attributes = {
      annotation_number: result.annotations.size + 1,
      annotation_text_id: text.id,
      creator: current_user,
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

  def edit
    @annotation = Annotation.find(params[:id])
    @assignment = Assignment.find(params[:assignment_id])
  end

  def destroy
    result = Result.find(params[:result_id])
    @annotation = result.annotations.find(params[:id])
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
    @annotation = Annotation.find(params[:id])
    @annotation_text = @annotation.annotation_text
    @annotation_text.update(content: params[:content])
  end
end
