class AnnotationsController < ApplicationController
  
  def index
    @assignments = Assignment.all(:order => :id)

  end
  
  def add_existing_annotation
    label = AnnotationLabel.find(params[:annotation_label_id])
    new_annotation = { 
      :line_start => params[:line_start], 
      :line_end => params[:line_end],
      :annotation_label_id => label.id,
      :submission_file_id => params[:fid]
    }
    annotation = Annotation.new(new_annotation)
    annotation.save
    render :update do |page|
      page.call(:add_annotation_label, label.id, label.content)
      page << "add_annotation($R(#{params[:line_start]}, #{params[:line_end]}), #{label.id})"
    end

  end

  def create
    new_label = {
      :content => params[:annotation_text]
    }
    label = AnnotationLabel.new(new_label)
    label.save
    
    new_annotation = { 
      :line_start => params[:line_start], 
      :line_end => params[:line_end],
      :annotation_label_id => label.id,
      :submission_file_id => params[:fid]
    }
    annotation = Annotation.new(new_annotation)
    annotation.save
    render :update do |page|
      page.call(:add_annotation_label, label.id, label.content)
      page << "add_annotation($R(#{params[:line_start]}, #{params[:line_end]}), #{label.id})"
    end
    
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
    @rubric_criteria = @assignment.rubric_criterias
    @annotation_categories = @assignment.annotation_categories
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
