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
      :content => params[:annotation_text],
      :annotation_category_id => params[:category_id]
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
    @rubric_criteria = @assignment.rubric_criterias(:order => 'position')
    @annotation_categories = @assignment.annotation_categories
    @uid = params[:uid]
    submission = @assignment.submission_by(User.find(@uid))
    @group = Membership.find_by_user_id(@uid).group
    @files = submission.submitted_filenames || []
    #link marks and criterias together
    #@marks_map = []
    #@rubric_criteria.each do |criterion|
    #  @marks_map[criterion.id] = Mark.find(:first,
    #    :conditions => ["group_id = :g AND criterion = :c", {:g=> @group, :c=>criterion}] )
    #end
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

  def update_mark
    mark = Mark.find(params[:mark_id]);
    if (mark.nil?)
      mark = Mark.new(:criterion => criterion_id, :mark=>mark_val, :group_id => group_id)
    else
      mark.mark = mark_val;
    end
    mark.save
    render :layout => false
  end

end
