class AnnotationsController < ApplicationController

  before_filter      :authorize_for_ta_and_admin

  def add_existing_annotation
    return unless request.post?
    @text = AnnotationText.find(params[:annotation_text_id])
    @submission_file_id = params[:submission_file_id]
    @submission_file = SubmissionFile.find(@submission_file_id)
    submission= @submission_file.submission
    is_remark = submission.has_remark?

    if params[:annotation_type] == 'image'
      @annotation = ImageAnnotation.new
      @annotation.update_attributes({
        x1: Integer(params[:x1]), x2: Integer(params[:x2]),
        y1: Integer(params[:y1]), y2: Integer(params[:y2]),
        submission_file_id: @submission_file_id,
        is_remark: is_remark,
        annotation_number: submission.annotations.count + 1
      })
    elsif params[:annotation_type] == 'pdf'
      @annotation = PdfAnnotation.new
      @annotation.update_attributes(x1: Integer(params[:x1]),
                                    x2: Integer(params[:x2]),
                                    y1: Integer(params[:y1]),
                                    y2: Integer(params[:y2]),
                                    page: Integer(params[:page]),
                                    submission_file_id: @submission_file_id,
                                    is_remark: is_remark,
                                    annotation_number: submission.annotations
                                                                 .count + 1
                                   )
    else
      @annotation = TextAnnotation.new
      @annotation.update_attributes({
        line_start: params[:line_start],
        line_end: params[:line_end],
        column_start: params[:column_start],
        column_end: params[:column_end],
        submission_file_id: @submission_file_id,
        is_remark: is_remark,
        annotation_number: submission.annotations.count + 1
      })
    end
    @annotation.annotation_text = @text
    @annotation.save
    @submission = @submission_file.submission
    @annotations = @submission.annotations
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
    is_remark = submission.has_remark?
    case params[:annotation_type]
    when 'text'
      @annotation = TextAnnotation.create(
        line_start: params[:line_start],
        line_end: params[:line_end],
        column_start: params[:column_start],
        column_end: params[:column_end],
        annotation_text_id: @text.id,
        submission_file_id: @submission_file_id,
        is_remark: is_remark,
        annotation_number: submission.annotations.count + 1
      )
    when 'image'
      @annotation = ImageAnnotation.create(
        annotation_text_id: @text.id,
        submission_file_id: @submission_file_id,
        x1: Integer(params[:x1]),
        x2: Integer(params[:x2]),
        y1: Integer(params[:y1]),
        y2: Integer(params[:y2]),
        is_remark: is_remark,
        annotation_number: submission.annotations.count + 1
      )
    when 'pdf'
      @annotation = PdfAnnotation.create(
        annotation_text_id: @text.id,
        submission_file_id: @submission_file_id,
        x1: Integer(params[:x1]),
        x2: Integer(params[:x2]),
        y1: Integer(params[:y1]),
        y2: Integer(params[:y2]),
        page: Integer(params[:page]),
        is_remark: is_remark,
        annotation_number: submission.annotations.count + 1
      )
    end

    @submission = @submission_file.submission
    @annotations = @submission.annotations
  end

  def destroy
    @annotation = Annotation.find(params[:id])
    @text_annotation = @annotation.annotation_text
    @text_annotation.destroy if @text_annotation.annotation_category.nil?
    @old_annotation = @annotation.destroy
    @submission_file_id = params[:submission_file_id]
    @submission_file = SubmissionFile.find(@submission_file_id)
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
    @content = params[:annotation_text][:content]
    @id = params[:annotation_text][:id]
    @submission_file_id = params[:annotation_text][:submission_file_id]
    @annotation_text = AnnotationText.find(@id)
    @annotation_text.content = @content
    @annotation_text.save
    @submission_file = SubmissionFile.find(@submission_file_id)
    @submission = @submission_file.submission
    @annotations = @submission.annotations
  end
end
