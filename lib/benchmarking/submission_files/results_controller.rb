class ResultsController < ApplicationController
  before_filter      :authorize_only_for_admin, :except => [:codeviewer,
  :edit, :update_mark, :view_marks, :create, :add_extra_mark, :next_grouping, :update_overall_comment, :expand_criteria, :collapse_criteria, :remove_extra_mark]
  before_filter      :authorize_for_ta_and_admin, :only => [:edit,
  :update_mark, :create, :add_extra_mark, :download, :next_grouping, :update_overall_comment, :expand_criteria, :collapse_criteria, :remove_extra_mark]
  before_filter      :authorize_for_user, :only => [:codeviewer]
  before_filter      :authorize_for_student, :only => [:view_marks]

  def create
    # Create new Result for this Submission
    @submission_id = params[:id]
    @submission = Submission.find(@submission_id)
    
    # Is there already a result for this Submission?
    if @submission.has_result?
      # If so, our new Result needs to have a version number greater than the
      # old result version.  We're also going to set this new result to be current.
      old_result = @submission.get_result_used
      old_result.result_version_used = false
      old_result.save
    end
    
    new_result = Result.new
    new_result.submission = @submission
    new_result.marking_state = Result::MARKING_STATES[:partial]
    new_result.save
    redirect_to :action => 'edit', :id => new_result.id
  end
  
  def index
  end
  
  def edit
    result_id = params[:id]
    @result = Result.find(result_id)
    if @result.released_to_students
       flash[:fail_notice] = 'The marks have been released. You cannot
       change the grades.'
    end
    @assignment = @result.submission.assignment
    @rubric_criteria = @assignment.rubric_criteria
    @submission = @result.submission
    @annotation_categories = @assignment.annotation_categories
    @grouping = @result.submission.grouping
    @group = @grouping.group
    @files = @submission.submission_files
    @first_file = @files.first
    @extra_marks_points = @result.extra_marks.points
    @extra_marks_percentage = @result.extra_marks.percentage
    @marks_map = []
    @rubric_criteria.each do |criterion|
      mark = Mark.find_or_create_by_result_id_and_rubric_criterion_id(@result.id, criterion.id)
      mark.save(:validate => false)
      @marks_map[criterion.id] = mark
    end

    # Get the previous and the next submission
    if current_user.ta?
       groupings = []
       @assignment.ta_memberships.find_all_by_user_id(current_user.id).each do |membership|
         groupings.push(membership.grouping)
       end
    end

    if current_user.admin?
      groupings = @assignment.groupings
    end
    
    current_grouping_index = groupings.index(@grouping)
    if groupings[current_grouping_index + 1]
      @next_grouping = groupings[current_grouping_index + 1]
    end
    if (current_grouping_index - 1) >= 0
      @previous_grouping = groupings[current_grouping_index - 1]
    end

  end

  def next_grouping
    grouping = Grouping.find(params[:id])
    if grouping.has_submission?
      redirect_to :action => 'edit', :id => grouping.get_submission_used.get_latest_result.id
    else
      redirect_to :controller => 'submissions', :action => 'collect_and_begin_grading', :id => grouping.assignment.id, :grouping_id => grouping.id
    end
  end
  
  def download
    file = SubmissionFile.find(params[:select_file_id])
    begin
      file_contents = retrieve_file(file)
    rescue Exception => e
      flash[:file_download_error] = e.message
      redirect_to :action => 'edit', :id => file.submission.get_latest_result.id
      return
    end
    send_data file_contents, :disposition => 'inline', :filename => file.filename
  end
  
  def codeviewer
    @assignment = Assignment.find(params[:id])
    @submission_file_id = params[:submission_file_id]
    @focus_line = params[:focus_line]
      
    @file = SubmissionFile.find(@submission_file_id)
    @result = @file.submission.get_latest_result
    # Is the current user a student?
    if current_user.student?
      # The Student does not have access to this file.  Render nothing.
      if @file.submission.grouping.membership_status(current_user).nil?
        raise "No access to submission file with id #{@submission_file_id}"
      end
    end

    @annots = @file.annotations    
    @all_annots = @file.submission.annotations

    begin
      @file_contents = retrieve_file(@file)
    rescue Exception => e
      render :update do |page|
        page.call 'alert', e.message
      end
      return
    end   
    
    @code_type = @file.get_file_type
    render :'results/common/codeviewer'
  end
  
  def update_mark
    result_mark = Mark.find(params[:mark_id])
    mark_value = params[:mark]
    result_mark.mark = mark_value
    if result_mark.save
      render :update do |page|
        page.call 'select_mark', result_mark.id, mark_value
        page.replace_html "rubric_criterion_title_#{result_mark.id.to_s}_mark",
                          "<b> #{result_mark.mark} #{result_mark.rubric_criterion
                          ['level_' + result_mark.mark.to_s + '_name']
                          }</b> #{result_mark.rubric_criterion
                          ['level_' + result_mark.mark.to_s + '_description']}"
        page.replace_html "mark_#{result_mark.id.to_s}_summary_mark", result_mark.mark
        page.replace_html "mark_#{result_mark.id.to_s}_summary_mark_after_weight",
                          (result_mark.mark * result_mark.rubric_criterion.weight)
        page.replace_html 'current_subtotal_div', result_mark.result.get_subtotal
        page.call 'update_total_mark', result_mark.result.total_mark
      end
    else
      render :update do |page|
        page.call 'alert', 'Could not save this mark!: ' + result_mark.errors
      end
    end
  end
  
  def view_marks
    @assignment = Assignment.find(params[:id])
    @grouping = current_user.accepted_grouping_for(@assignment.id)

    if @grouping.nil?
      redirect_to :controller => 'assignments', :action => 'student_interface', :id => params[:id]
      return
    end
    
    unless @grouping.has_submission?
      render 'results/student/no_submission'
      return
    end
    @submission = @grouping.get_submission_used
    unless @submission.has_result?
      render 'results/student/no_result'
      return
    end
    @result = @submission.get_original_result
    @old_result = nil
    if @submission.remark_submitted?
      @old_result = @result
      @result = @submission.get_remark_result
      # if remark result's marking state is 'unmarked' then the student has
      # saved a remark request but not submitted it yet, therefore, still editable
      if @result.marking_state != Result::MARKING_STATES[:unmarked] && !@result.released_to_students
        render 'results/student/no_remark_result'
        return
      end
    end

    unless @result.released_to_students
      render 'results/student/no_result'
      return
    end
    @rubric_criteria = @assignment.rubric_criteria
    @annotation_categories = @assignment.annotation_categories
    @group = @grouping.group
    @files = @submission.submission_files
    @first_file = @files.first
    @extra_marks_points = @result.extra_marks.points
    @extra_marks_percentage = @result.extra_marks.percentage
    @marks_map = []
    @rubric_criteria.each do |criterion|
      mark = Mark.find_or_create_by_result_id_and_rubric_criterion_id(@result.id, criterion.id)
      mark.save(:validate => false)
      @marks_map[criterion.id] = mark
    end
  end
  
  def add_extra_mark
    @result = Result.find(params[:id])
    if request.post?
      @extra_mark = ExtraMark.new
      @extra_mark.result = @result
      @extra_mark.update_attributes(params[:extra_mark])
      @extra_mark.unit = ExtraMark::UNITS[:points]
      if @extra_mark.save
        render :'results/marker/insert_extra_mark'
      else
        render :'results/marker/add_extra_mark_error'
      end
      return
    end
    render :'results/marker/add_extra_mark'
  end

  #Deletes an extra mark from the database and removes it from the html
  def remove_extra_mark
    #find the extra mark and destroy it
    @extra_mark = ExtraMark.find(params[:id])
    @extra_mark.destroy
    #need to recalculate total mark
    @result = @extra_mark.result
    render :'results/marker/remove_extra_mark'
  end

  #update the mark and/or description of the extra mark
  def update_extra_mark
    extra_mark = ExtraMark.find(params[:id])
    #the attribute to be changed - description or mark
    type = params[:type]
    #the new attribute value
    val = params[:value]
    #change the value
    extra_mark[type] = val

    #save it
    if extra_mark.valid? && extra_mark.save
      #need to update the total mark
      result = Result.find(extra_mark.result_id)
      result.calculate_total
      render :update do |page|
        #The following divs need to be changed
        #1 the display of the extra mark
        page.replace_html("extra_mark_title_#{extra_mark.id}_" + type, val)
        #2 the display of the total mark
        page.replace_html('current_total_mark_div', result.total_mark)
        #3 the divs containing deductions/bonuses
        page.replace_html('extra_marks_bonus', result.get_bonus_marks)
        page.replace_html('extra_marks_deducted', result.get_deductions)
        #4 the div containing the total mark at the top of the page
        page.replace_html('current_mark_div', result.total_mark)
      end
    else
      output = {'status' => 'error'}
      render :json => output.to_json
    end
  end
  
  def update_overall_comment
    @result = Result.find(params[:id])
    @result.overall_comment = params[:result][:overall_comment]
    @result.save
  end
  
  def expand_criteria
    @assignment = Assignment.find(params[:aid])
    @rubric_criteria = @assignment.rubric_criteria
    render :partial => 'results/marker/expand_criteria', :locals => {:rubric_criteria => @rubric_criteria}
  end
  
  def collapse_criteria
    @assignment = Assignment.find(params[:aid])
    @rubric_criteria = @assignment.rubric_criteria
    render :partial => 'results/marker/collapse_criteria', :locals => {:rubric_criteria => @rubric_criteria}
  end
  
  def expand_unmarked_criteria
    @assignment = Assignment.find(params[:aid])
    @rubric_criteria = @assignment.rubric_criteria
    @result = Result.find(params[:rid])
    # nil_marks are the marks that have a "nil" value for Mark.mark - so they're
    # unmarked.
    @nil_marks = @result.marks.all(:conditions => {:mark => nil})
    render :partial => 'results/marker/expand_unmarked_criteria', :locals => {:nil_marks => @nil_marks}
  end
  
  private
  
  def retrieve_file(file)
    student_group = file.submission.grouping.group
    repo = student_group.repo
    revision_number = file.submission.revision_number
    revision = repo.get_revision(revision_number)
    if revision.files_at_path(file.path)[file.filename].nil?
      raise "Could not find #{file.filename} in repository #{student_group.repository_name}"
    end
    repo.download_as_string(revision.files_at_path(file.path)[file.filename])
  end
  
end
