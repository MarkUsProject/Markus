class AnnotationsController < ApplicationController
  
  before_filter      :authorize_for_ta_and_admin
  
  # TODO: Is the assignment closed?  If so, begin generating 
  # Submissions and SubmissionFiles
   
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
    result.save
    render :update do |page|
    end
  end

  #Updates the marking state
  def update_marking_state
    result = Result.find(params[:id])
    result.marking_state = params[:value]
    result.save
    render :update do |page|
       page.redirect_to :controller => 'results', :action => 'edit', :id =>
       result.id
    end
  end


  #Creates a gradesfile in the format specified by
  #http://www.cs.toronto.edu/~clarke/grade/new/fileformat.html

#  def get_gradesfile
#    file_out = ""
#    assignments = Assignment.find(:all, :order => "id")
#    students = User.find_all_by_role('student')
#    results = Result.all
#    #need to create the header, which is the list of assignments and their total
#    #mark
#    assignments.each do |asst|
#      str = asst.name.tr(" ", "") + ' / ' + asst.total_mark.to_s;
#      file_out << str + "\n"
#    end

#    file_out << "\n"
#   
#    #next we generate the list of students and marks
#    #student# + four spaces + student last name + 2 spaces + student first name
#    # + marks (each preceded by a tab char)
#    students.each do |student|
#      str = ""
#      str << student.user_number + "    " + student.last_name + "  " + student.first_name

#      #for each assignment add the mark to the line
#      assignments.each do |asst|
#        #get the student's group for this assignment
#        group = asst.group_by(student.id);
#        next if group.nil?
#        #find the corresponding submission
#        sub = Submission.find_by_group_id(group.id)
#        next if sub.nil?
#        #find the corresponding result
#        result = Result.find_by_submission_id(sub.id)
#        next if result.nil?
#        str << "\t" + result.total_mark.to_s
#      end

#      file_out << str + "\n"
#    end

#    send_data(file_out, :type => "text", :disposition => "inline")
#  end
#  
end
