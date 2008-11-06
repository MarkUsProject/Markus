class AnnotationsController < ApplicationController
  def index
    @assignments = Assignment.all(:order => :id)
  end

  def students
    @students = User.students
    @aid = params[:id]
    @aname = Assignment.find(@aid).name
  end

  def grader
    @assignment = Assignment.find(params[:aid])
    @uid = params[:uid]
    submission = @assignment.submission_by(User.find(@uid))
    @files = submission.submitted_filenames || []
  end

  def codeviewer
    @assignment = Assignment.find(params[:id])
    submission = @assignment.submission_by(User.find(params[:uid]))
    
    dir = submission.submit_dir

    if params[:filename] != "None"
      filepath = File.join(dir, params[:filename])

      filetext = File.read(filepath)

    else

      filetext = ""

    end

    render :partial => "codeviewer", :locals => { :uid => params[:uid], :filetext => filetext }
    
  end
end
