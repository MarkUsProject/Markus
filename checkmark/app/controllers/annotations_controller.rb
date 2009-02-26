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
    @files = submission.submitted_filenames || []
    #Get the result object
    @result = Result.find_by_submission_id(submission.id)
    if (@result == nil)
      @result = Result.new(:submission_id=>submission.id, :marking_state=>"unmarked");
      @result.save
    end
    #link marks and criterias together
    @marks_map = []
    @rubric_criteria.each do |criterion|
      @marks_map[criterion.id] = Mark.find(:first,
        :conditions => ["result_id = :r AND criterion_id = :c", {:r=> @result.id, :c=>criterion.id}] )
    end
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
    criterion = RubricCriteria.find(mark.criterion_id);
    mark.mark = params[:mark];
    mark.save
    result = Result.find(mark.result_id)
    result.marking_state = "partial"
    result.calculate_total
    result.save
    render :update do |page|
      page.replace_html("mark_#{mark.id}_current",  mark.get_mark.to_s + "/")
      page.replace_html("current_mark_div", result.total_mark)
      #<%= criterion.weight %> * <%= mark.mark %> =
      #<%= mark.mark*criterion.weight %> / <%=  criterion.weight * 4 %>
      page.replace_html("mark_summary_#{mark.id}",  criterion.weight.to_s + " * " + mark.mark.to_s + " = " + (mark.mark*criterion.weight).to_s + " / " + (criterion.weight * 4).to_s)
    end
  end

  def update_comment
    result = Result.find(params[:result_id])
    result.overall_comment = params[:overall_comment]
    result.save;
    render :update do |page|
    end
  end

end
