class AnnotationsController < ApplicationController
  def index
    @assignments = Assignment.all(:order => :id)
  end

  def create
    new_annotation = { 
      :pos_start => params[:pos_start],
      :pos_end => params[:pos_end], 
      :line_start => params[:line_start], 
      :line_end => params[:line_end],
      :description_id => 1,
      :submission_file_id => params[:fid]
    }
    a = Annotation.new(new_annotation)
    a.save
    render :text => a.inspect
  end

  def destroy
    @annot = Annotation.find(params[:id])
    @annot.destroy
  end

  def students
    @students = User.students
    @aid = params[:id]
    @assignment = Assignment.find(@aid)
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
    @fid = params[:fid]
    file = SubmissionFile.find(@fid)
    annots = Annotation.find(:all, :conditions => ['submission_file_id = ?', @fid] )
    
    dir = submission.submit_dir

    filepath = File.join(dir, file.filename)

    filetext = File.read(filepath)

    render :partial => "codeviewer", :locals =>
      { :uid => params[:uid], :filetext => filetext, :annots => annots}
    
  end
end
