class AnnotationsController < ApplicationController

  before_action(except: :add_existing_annotation) do |c|
    c.authorize_for_ta_admin_and_reviewer(params[:assignment_id], params[:result_id])
  end

  before_action :authorize_for_ta_and_admin, only: :add_existing_annotation

  def add_existing_annotation
    @text = AnnotationText.find(params[:annotation_text_id])
    submission_file = SubmissionFile.find(params[:submission_file_id])
    submission = submission_file.submission
    base_attributes = {
      submission_file_id: submission_file.id,
      is_remark: submission.has_remark?,
      annotation_text_id: params[:annotation_text_id],
      annotation_number: submission.annotations.count + 1,
      creator_id: current_user.id,
      creator_type: current_user.type,
      result_id: params[:result_id]
    }

    if submission_file.is_supported_image?
      @annotation = ImageAnnotation.create(
        x1: params[:x1],
        y1: params[:y1],
        x2: params[:x2],
        y2: params[:y2],
        **base_attributes
      )
    elsif submission_file.is_pdf?
      @annotation = PdfAnnotation.create(
        x1: params[:x1],
        y1: params[:y1],
        x2: params[:x2],
        y2: params[:y2],
        page: params[:page],
        **base_attributes
      )
    else
      @annotation = TextAnnotation.create(
        line_start: params[:line_start],
        line_end: params[:line_end],
        column_start: params[:column_start],
        column_end: params[:column_end],
        **base_attributes
      )
    end
    render :create
  end

  def new
    @result = Result.find(params[:result_id])
    @assignment = @result.submission.grouping.assignment
  end

  def create
    @text = AnnotationText.create({
      content: params[:content],
      annotation_category_id: params[:category_id],
      creator_id: current_user.id,
      last_editor_id: current_user.id
    })
    @submission_file_id = params[:submission_file_id]
    @submission_file = SubmissionFile.find(@submission_file_id)
    submission= @submission_file.submission
    result_id = params[:result_id]
    is_remark = submission.has_remark?
    case params[:annotation_type]
    when 'text'
      @annotation = TextAnnotation.create!(
        line_start: params[:line_start],
        line_end: params[:line_end],
        column_start: params[:column_start],
        column_end: params[:column_end],
        annotation_text_id: @text.id,
        submission_file_id: @submission_file_id,
        creator_id: current_user.id,
        creator_type: current_user.type,
        is_remark: is_remark,
        annotation_number: submission.annotations.count + 1,
        result_id: result_id
      )
    when 'image'
      @annotation = ImageAnnotation.create!(
        annotation_text_id: @text.id,
        submission_file_id: @submission_file_id,
        x1: Integer(params[:x1]),
        x2: Integer(params[:x2]),
        y1: Integer(params[:y1]),
        y2: Integer(params[:y2]),
        creator_id: current_user.id,
        creator_type: current_user.type,
        is_remark: is_remark,
        annotation_number: submission.annotations.count + 1,
        result_id: result_id
      )
    when 'pdf'
      @annotation = PdfAnnotation.create!(
        annotation_text_id: @text.id,
        submission_file_id: @submission_file_id,
        x1: Integer(params[:x1]),
        x2: Integer(params[:x2]),
        y1: Integer(params[:y1]),
        y2: Integer(params[:y2]),
        page: Integer(params[:page]),
        creator_id: current_user.id,
        creator_type: current_user.type,
        is_remark: is_remark,
        annotation_number: submission.annotations.count + 1,
        result_id: result_id
      )
    end

    @submission = @submission_file.submission
    @annotations = @submission.annotations
  end

  def edit
    @annotation = Annotation.find(params[:id])
    @text_annotation = @annotation.annotation_text
  end

  def destroy
    @annotation = Annotation.find(params[:id])
    @text_annotation = @annotation.annotation_text
    @text_annotation.destroy if @text_annotation.annotation_category.nil?
    @old_annotation = @annotation.destroy
    @submission_file = @annotation.submission_file
    @submission = @submission_file.submission
    @annotations = @submission.annotations
    @annotations.each do |annot|
      if annot.annotation_number > @old_annotation.annotation_number
        annot.annotation_number -= 1
        annot.save
      end
    end
  end

  def update_annotation
    @content = params[:content]
    @annotation = Annotation.find(params[:id])
    @annotation_text = @annotation.annotation_text
    @annotation_text.content = @content
    @annotation_text.save
    @submission_file = @annotation.submission_file
    @submission = @submission_file.submission
    @annotations = @submission.annotations
    @result_id = params[:result_id]
  end
end
