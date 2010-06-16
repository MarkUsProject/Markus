class AnnotationsController < ApplicationController
  
  before_filter      :authorize_for_ta_and_admin

  # Not possible to do with image annotations.
  def add_existing_annotation
    return unless request.post?
    @text = AnnotationText.find(params[:annotation_text_id])
    @submission_file_id = params[:submission_file_id]
    @submission_file = SubmissionFile.find(@submission_file_id)
    @annotation = TextAnnotation.new
    @annotation.update_attributes({
      :line_start => params[:line_start], 
      :line_end => params[:line_end],
      :submission_file_id => params[:submission_file_id]
    })
    @annotation.annotation_text = @text
    @annotation.save
    @submission = @submission_file.submission
    @annotations = @submission.annotations
  end

  def create
    return unless request.post?
    @text = AnnotationText.create({
      :content => params[:content],
      :annotation_category_id => params[:category_id]
    })
    @submission_file_id = params[:submission_file_id]
    @submission_file = SubmissionFile.find(@submission_file_id)
    case params[:annotation_type]
      when 'text'
        @annotation = TextAnnotation.create({
          :line_start => params[:line_start],
          :line_end => params[:line_end],
          :annotation_text_id => @text.id,
          :submission_file_id => params[:submission_file_id]
        })
      when 'image'
        @annotation = ImageAnnotation.create({
          :annotation_text_id => @text.id,
          :submission_file_id => params[:submission_file_id],
          :x1 => Integer(params[:x1]), :x2 => Integer(params[:x2]),
          :y1 => Integer(params[:y1]), :y2 => Integer(params[:y2])
        })
    end
    @submission = @submission_file.submission
    @annotations = @submission.annotations
  end

  def destroy
    return unless request.post?
    @annotation = Annotation.find(params[:id])
    @old_annotation = @annotation.destroy
    @submission_file_id = params[:submission_file_id]
    @submission_file = SubmissionFile.find(@submission_file_id)
    @submission = @submission_file.submission
    @annotations = @submission.annotations
  end
 
  def update_annotation
    return unless request.post?
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

  #Updates the overall comment from the annotations tab
  def update_comment
    return unless request.post?
    result = Result.find(params[:result_id])
    result.overall_comment = params[:overall_comment]
    result.save;
    render :update do |page|
    end
  end

end
