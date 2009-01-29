class AnnotationsController < ApplicationController
  def index
    @assignments = Assignment.all(:order => :id)
  end

  def create
    new_label = {
      :name => params[:annotation_text][0, 8] + '...',
      :content => params[:annotation_text],
      :annotation_category_id => 1,  #TODO:  Maybe change from default?
    }
    label = AnnotationLabel.new(new_label)
    label.save
    
    new_annotation = { 
      :pos_start => params[:pos_start],
      :pos_end => params[:pos_end], 
      :line_start => params[:line_start], 
      :line_end => params[:line_end],
      :annotation_label_id => label.id,
      :submission_file_id => params[:fid]
    }
    annotation = Annotation.new(new_annotation)
    annotation.save
    render :js => "
      render_annotation_label(" + annotation.id.to_s + ", \"" + label.content.to_s + "\");    
      highlightRange(" + params[:line_start].to_s + "," + params[:line_end].to_s + ").each(
      function(node) { add_tool_tip(node, " + annotation.id.to_s + "); });"
  end

  def destroy
    @annot = Annotation.find(params[:id])
    @annot.destroy
    render :text => 'OK'
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
    annots = Annotation.find_all_by_submission_file_id(@fid) || []
    dir = submission.submit_dir

    filepath = File.join(dir, file.filename)

    filetext = File.read(filepath)
    render :partial => "codeviewer", :locals =>
      { :uid => params[:uid], :filetext => filetext, :annots => annots}
    
  end
end
