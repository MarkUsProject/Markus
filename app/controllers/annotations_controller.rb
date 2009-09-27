class AnnotationsController < ApplicationController
  
  before_filter      :authorize_for_ta_and_admin
    
  def add_existing_annotation
    @text = AnnotationText.find(params[:annotation_text_id])
    @submission_file_id = params[:submission_file_id]
    @submission_file = SubmissionFile.find(@submission_file_id)
    @annotation = Annotation.new
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
    @text = AnnotationText.create({
      :content => params[:content],
      :annotation_category_id => params[:category_id]
    })
    @submission_file_id = params[:submission_file_id]
    @submission_file = SubmissionFile.find(@submission_file_id)
    @annotation = Annotation.create({ 
      :line_start => params[:line_start], 
      :line_end => params[:line_end],
      :annotation_text_id => @text.id,
      :submission_file_id => params[:submission_file_id]
    })
    @submission = @submission_file.submission
    @annotations = @submission.annotations
  end

  def destroy
    @annotation = Annotation.find(params[:id])
    @old_annotation = @annotation.destroy
    @submission_file_id = params[:submission_file_id]
    @submission_file = SubmissionFile.find(@submission_file_id)
    @submission = @submission_file.submission
    @annotations = @submission.annotations
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

  #Updates the overall comment from the annotations tab
  def update_comment
    result = Result.find(params[:result_id])
    result.overall_comment = params[:overall_comment]
    result.save;
    render :update do |page|
    end
  end

end
