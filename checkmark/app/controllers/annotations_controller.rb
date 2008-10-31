class AnnotationsController < ApplicationController
  def index
  end

  def grader
    @assignment = Assignment.find(params[:id])
    submission = @assignment.submission_by(current_user)
    @files = submission.submitted_filenames || []
  end

  def codeviewer
    @assignment = Assignment.find(params[:id])
    submission = @assignment.submission_by(current_user)
    
    dir = submission.submit_dir

    if params[:filename] != "None"
      filepath = File.join(dir, params[:filename])

      filetext = File.read(filepath)

    else

      filetext = ""

    end

    render :partial => "codeviewer", :locals => { :filetext => filetext }
    
  end
end
