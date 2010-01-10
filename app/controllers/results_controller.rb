class ResultsController < ApplicationController
  before_filter      :authorize_only_for_admin, :except => [:codeviewer, :edit, :update_mark, :view_marks,
                        :create, :add_extra_mark, :next_grouping, :update_overall_comment, :expand_criteria,
                        :collapse_criteria, :remove_extra_mark, :expand_unmarked_criteria, :update_marking_state,
                        :download, :note_message]
  before_filter      :authorize_for_ta_and_admin, :only => [:edit, :update_mark, :create, :add_extra_mark,
                        :download, :next_grouping, :update_overall_comment, :expand_criteria,
                        :collapse_criteria, :remove_extra_mark, :expand_unmarked_criteria,
                        :update_marking_state, :note_message]
  before_filter      :authorize_for_user, :only => [:codeviewer]
  before_filter      :authorize_for_student, :only => [:view_marks]
  
  def index
  end

  def note_message
    @result = Result.find(params[:id])
    if params[:success]
      flash[:note_success] = I18n.t('notes.success')
    else
      flash[:fail_notice] = I18n.t('notes.error')
    end
  end
  
  def edit
    result_id = params[:id]
    @result = Result.find(result_id)
    @assignment = @result.submission.assignment
    @rubric_criteria = @assignment.get_criteria      
    @submission = @result.submission
    @annotation_categories = @assignment.annotation_categories
    @grouping = @result.submission.grouping
    @group = @grouping.group
    @files = @submission.submission_files
    @first_file = @files.first
    @extra_marks_points = @result.extra_marks.points
    @extra_marks_percentage = @result.extra_marks.percentage
    @marks_map = Hash.new
    @rubric_criteria.each do |criterion|
      mark = criterion.marks.find_or_create_by_result_id(@result.id)
      mark.save(false)
      @marks_map[criterion.id] = mark
    end

    # Get the previous and the next submission
    if current_user.ta?
       groupings = @assignment.ta_memberships.find_all_by_user_id(current_user.id).collect do |m|       
         m.grouping
       end
    end

    if current_user.admin?
      groupings = @assignment.groupings
    end
    
    # If a grouping's submission's marking_status is complete, we're not going
    # to include them in the next_submission/prev_submission list
    
    # If a grouping doesn't have a submission, and we are past the collection time, 
    # we *DO* want to include them in the list.
    collection_time = @assignment.submission_rule.calculate_collection_time.localtime
    
    groupings.delete_if do |grouping|
      grouping != @grouping && (grouping.marking_completed? || (!grouping.has_submission? && (Time.now < collection_time)))
    end
    
    # We sort by Group name by default
    groupings = groupings.sort do |a, b|
      a.group.group_name <=> b.group.group_name
    end
    
    current_grouping_index = groupings.index(@grouping)
    if current_grouping_index.nil?
      @next_grouping = groupings.first
      @previous_grouping = groupings.last
    else
      if !groupings[current_grouping_index + 1].nil?
        @next_grouping = groupings[current_grouping_index + 1]
      end
      if (current_grouping_index - 1) >= 0
        @previous_grouping = groupings[current_grouping_index - 1]
      end
    end
  end

  def next_grouping
    grouping = Grouping.find(params[:id])
    if grouping.has_submission?
      redirect_to :action => 'edit', :id => grouping.get_submission_used.result.id
    else
      redirect_to :controller => 'submissions', :action => 'collect_and_begin_grading', :id => grouping.assignment.id, :grouping_id => grouping.id
    end
  end
  
  def set_released_to_students
    @result = Result.find(params[:id])
    released_to_students = (params[:value] == 'true')
    @result.released_to_students = released_to_students
    @result.save
    @result.submission.assignment.set_results_average
  end
  
  #Updates the marking state
  def update_marking_state
    @result = Result.find(params[:id])
    @result.marking_state = params[:value]
    @result.save
  end
  
  def download
    file = SubmissionFile.find(params[:select_file_id])
    begin
      file_contents = retrieve_file(file)
    rescue Exception => e
      flash[:file_download_error] = e.message
      redirect_to :action => 'edit', :id => file.submission.result.id
      return
    end
    send_data file_contents, :disposition => 'inline', :filename => file.filename
  end
  
  def codeviewer
    @assignment = Assignment.find(params[:id])
    @submission_file_id = params[:submission_file_id]
    @focus_line = params[:focus_line]
      
    @file = SubmissionFile.find(@submission_file_id)
    @result = @file.submission.result
    # Is the current user a student?
    if current_user.student?
      # The Student does not have access to this file. Display an error.
      if @file.submission.grouping.membership_status(current_user).nil?
        render :partial => 'shared/handle_error',
               :locals => {:error => I18n.t('submission_file.error.no_access', :submission_file_id => @submission_file_id)}
        return
      end
    end

    @annots = @file.annotations    
    @all_annots = @file.submission.annotations

    begin
      @file_contents = retrieve_file(@file)
    rescue Exception => e
      render :partial => 'shared/handle_error',
             :locals => {:error => e.message}
      return
    end   
    
    @code_type = @file.get_file_type
    render :action => 'results/common/codeviewer'
  end
  
  def update_mark
    result_mark = Mark.find(params[:mark_id])
    mark_value = params[:mark]
    result_mark.mark = mark_value
    if !result_mark.save
      render :partial => 'shared/handle_error', :locals => {:error => I18n.t('mark.error.save') + result_mark.errors}
    else
      render :partial => 'results/marker/update_mark',
             :locals => { :result_mark => result_mark, :mark_value => mark_value}
    end
  end
  
  def view_marks
    @assignment = Assignment.find(params[:id])
    @grouping = current_user.accepted_grouping_for(@assignment.id)

    if @grouping.nil?
      redirect_to :controller => 'assignments', :action => 'student_interface', :id => params[:id]
      return
    end
    if !@grouping.has_submission?
      render 'results/student/no_submission'
      return
    end
    @submission = @grouping.get_submission_used
    if !@submission.has_result?
      render 'results/student/no_result'
      return
    end
    @result = @submission.result
    if !@result.released_to_students
      render 'results/student/no_result'
      return
    end
    @rubric_criteria = @assignment.get_criteria
    @annotation_categories = @assignment.annotation_categories
    @group = @grouping.group
    @files = @submission.submission_files
    @first_file = @files.first
    @extra_marks_points = @result.extra_marks.points
    @extra_marks_percentage = @result.extra_marks.percentage
    @marks_map = Hash.new
    @rubric_criteria.each do |criterion|
      mark = criterion.marks.find_or_create_by_result_id(@result.id)
      mark.save(false)
      @marks_map[criterion.id] = mark
    end
  end
  
  def add_extra_mark
    @result = Result.find(params[:id])
    if request.post?
      @extra_mark = ExtraMark.new
      @extra_mark.result = @result
      @extra_mark.unit = ExtraMark::UNITS[:points]
      if !@extra_mark.update_attributes(params[:extra_mark])
        render :action => 'results/marker/add_extra_mark_error'
      else
        render :action => 'results/marker/insert_extra_mark'
      end
      return
    end

    render :action => 'results/marker/add_extra_mark'
  end

  #Deletes an extra mark from the database and removes it from the html
  def remove_extra_mark
    #find the extra mark and destroy it
    @extra_mark = ExtraMark.find(params[:id])
    @extra_mark.destroy
    #need to recalculate total mark
    @result = @extra_mark.result
    render :action => 'results/marker/remove_extra_mark'
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
    return repo.download_as_string(revision.files_at_path(file.path)[file.filename])
  end
  
end
