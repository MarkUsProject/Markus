class ResultsController < ApplicationController
  before_filter :authorize_only_for_admin,
                :except => [:codeviewer,
                            :edit,
                            :update_mark,
                            :view_marks,
                            :create,
                            :add_extra_mark, :next_grouping, :update_overall_comment, :expand_criteria,
                        :collapse_criteria, :remove_extra_mark, :expand_unmarked_criteria, :update_marking_state,
                        :download, :note_message,
                        :update_overall_remark_comment, :update_remark_request, :cancel_remark_request]
  before_filter      :authorize_for_ta_and_admin, :only => [:edit, :update_mark, :create, :add_extra_mark,
                        :next_grouping, :update_overall_comment, :expand_criteria,
                        :collapse_criteria, :remove_extra_mark, :expand_unmarked_criteria,
                        :update_marking_state, :note_message, :update_overall_remark_comment]
  before_filter      :authorize_for_user, :only => [:codeviewer, :download]
  before_filter      :authorize_for_student, :only => [:view_marks, :update_remark_request, :cancel_remark_request]

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
    @submission = @result.submission

    @old_result = nil
    if @submission.remark_submitted?
      @old_result = @submission.result
    end

    @annotation_categories = @assignment.annotation_categories
    @grouping = @result.submission.grouping
    @group = @grouping.group
    @files = @submission.submission_files.sort do |a, b|
      File.join(a.path, a.filename) <=> File.join(b.path, b.filename)
    end
    @test_result_files = @submission.test_results
    @first_file = @files.first
    @extra_marks_points = @result.extra_marks.points
    @extra_marks_percentage = @result.extra_marks.percentage
    @marks_map = Hash.new
    @old_marks_map = Hash.new
    @mark_criteria = @assignment.get_criteria
    @assignment.get_criteria.each do |criterion|
      mark = criterion.marks.find_or_create_by_result_id(@result.id)
      mark.save(:validate => false)
      @marks_map[criterion.id] = mark

      if @old_result
        oldmark = criterion.marks.find_or_create_by_result_id(@old_result.id)
        oldmark.save(false)
        @old_marks_map[criterion.id] = oldmark
      end
    end

    # Get the previous and the next submission
    # FIXME right now, the groupings are ordered by grouping's id. Having a
    # more natural grouping order would be nice.
    if current_user.ta?
       groupings = @assignment.ta_memberships.find_all_by_user_id(
                      current_user.id,
                      :include => [:grouping => :group],
                      :order => 'id ASC').collect do |m|
         m.grouping
       end
    elsif current_user.admin?
      groupings = @assignment.groupings.find(
                      :all,
                      :include => :group,
                      :order => 'id ASC')
    end

    # If a grouping's submission's marking_status is complete, we're not going
    # to include them in the next_submission/prev_submission list

    # If a grouping doesn't have a submission, and we are past the collection time,
    # we *DO* want to include them in the list.
    collection_time = @assignment.submission_rule.calculate_collection_time.localtime

    groupings.delete_if do |grouping|
      grouping != @grouping && ((!grouping.has_submission? && (Time.now < collection_time)))
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
    m_logger = MarkusLogger.instance
    m_logger.log("User '#{current_user.user_name}' viewed submission (id: #{@submission.id})" +
                 "of assignment '#{@assignment.short_identifier}' for group '" +
                 "#{@group.group_name}'")

  end

  def next_grouping
    grouping = Grouping.find(params[:id])
    if grouping.has_submission? && grouping.is_collected? && grouping.current_submission_used.remark_submitted?
        redirect_to :action => 'edit',
                    :id => grouping.current_submission_used.remark_result.id
    elsif grouping.has_submission? && grouping.is_collected?
      redirect_to :action => 'edit',
                  :id => grouping.current_submission_used.result.id
    else
      redirect_to :controller => 'submissions',
                  :action => 'collect_and_begin_grading',
                  :id => grouping.assignment.id,
                  :grouping_id => grouping.id
    end
  end

  def set_released_to_students
    @result = Result.find(params[:id])
    released_to_students = (params[:value] == 'true')
    if (params[:old_id])
      @old_result = Result.find(params[:old_id])
      @old_result.released_to_students = released_to_students
      @old_result.save
    end
    @result.released_to_students = released_to_students
    @result.save
    @result.submission.assignment.set_results_average
    m_logger = MarkusLogger.instance
    assignment = @result.submission.assignment
    if params[:value] == 'true'
      m_logger.log("Marks released for assignment '#{assignment.short_identifier}', ID: '" +
                   "#{assignment.id}' (for 1 group).")
    else
      m_logger.log("Marks unreleased for assignment '#{assignment.short_identifier}', ID: '" +
                   "#{assignment.id}' (for 1 group).")
    end
  end

  #Updates the marking state
  def update_marking_state
    @result = Result.find(params[:id])
    @result.marking_state = params[:value]
    if @result.save
      # If marking_state is complete, update the cached distribution
      if params[:value] == Result::MARKING_STATES[:complete]
        @result.submission.assignment.assignment_stat.refresh_grade_distribution
      end
      render :template => "results/update_marking_state"
    else # Failed to pass validations
      # Show error message
      render :template => "results/marker/show_result_error"
      return
    end
  end

  def download
    #Ensure student doesn't download a file not submitted by his own grouping
    if !authorized_to_download?(params[:select_file_id])
      render 'shared/http_status.html', :locals => { :code => "404", :message => HttpStatusHelper::ERROR_CODE["message"]["404"] }, :status => 404, :layout => false
      return
    end
    file = SubmissionFile.find(params[:select_file_id])
    begin
      if params[:include_annotations] == 'true' && !file.is_supported_image?
        file_contents = file.retrieve_file(true)
      else
        file_contents = file.retrieve_file
      end
    rescue Exception => e
      flash[:file_download_error] = e.message
      redirect_to :action => 'edit',
                  :assignment_id => params[:assignment_id],
                  :submission_id => file.submission,
                  :id => file.submission.result
      return
    end
    filename = file.filename
    #Display the file in the page if it is an image/pdf, and download button
    #was not explicitly pressed
    if file.is_supported_image? && !params[:show_in_browser].nil?
      send_data file_contents, :type => "image", :disposition => 'inline',
        :filename => filename
    elsif file.is_pdf? && !params[:show_in_browser].nil?
      send_file File.join(MarkusConfigurator.markus_config_pdf_storage,
        file.submission.grouping.group.repository_name, file.path,
        filename.split('.')[0] + '_' + sprintf("%04d" % params[:file_index].to_s()) + '.jpg'),
        :type => "image", :disposition => 'inline', :filename => filename
    else
      send_data file_contents, :filename => filename
    end
  end

  def codeviewer
    @assignment = Assignment.find(params[:assignment_id])
    @submission_file_id = params[:submission_file_id]
    @focus_line = params[:focus_line]

    @file = SubmissionFile.find(@submission_file_id)
    @result = @file.submission.result
    # Is the current user a student?
    if current_user.student?
      # The Student does not have access to this file. Display an error.
      if @file.submission.grouping.membership_status(current_user).nil?
        render :partial => 'shared/handle_error',
               :locals => {:error => I18n.t('submission_file.error.no_access',
                 :submission_file_id => @submission_file_id)}
        return
      end
    end

    @annots = @file.annotations
    @all_annots = @file.submission.annotations

    begin
      @file_contents = @file.retrieve_file
    rescue Exception => e
      render :partial => 'shared/handle_error',
             :locals => {:error => e.message}
      return
    end
    @code_type = @file.get_file_type

    # if dealing with a pdf file, get the number of images to display
    if @file.is_pdf? 
      i = 1 
      storage_path = File.join(MarkusConfigurator.markus_config_pdf_storage,
        @file.submission.grouping.group.repository_name,
        @file.path)
      filePathToCheck = File.join(storage_path, @file.filename.split('.')[0] + '_' + sprintf("%04d" % i.to_s()) + '.jpg')
      while File.exists?(filePathToCheck)
        i += 1
        filePathToCheck = File.join(storage_path, @file.filename.split('.')[0] + '_' + sprintf("%04d" % i.to_s()) + '.jpg')
      end
      i -= 1
      @nb_pdf_files_to_download = i
    end

    render :template => 'results/common/codeviewer'
  end

  def update_mark
    result_mark = Mark.find(params[:mark_id])
    result_mark.mark = params[:mark]
    submission = result_mark.result.submission  # get submission for logging
    group = submission.grouping.group           # get group for logging
    assignment = submission.grouping.assignment # get assignment for logging
    m_logger = MarkusLogger.instance

    # FIXME checking both that result_mark is valid and correctly saved is
    # useless. The validation is done automatically before saving unless
    # specified otherwise.
    if !result_mark.valid?
      render :partial => 'results/marker/mark_verify_result',
             :locals => {:mark_id => result_mark.id,
                         :mark_error => result_mark.errors.full_messages.join}
    else
      if !result_mark.save
          m_logger.log("Error while trying to update mark of submission. User: '" +
                       "#{current_user.user_name}', Submission ID: '#{submission.id}'," +
                       " Assignment: '#{assignment.short_identifier}', Group: '#{group.group_name}'.",
                       MarkusLogger::ERROR)
          render :partial => 'shared/handle_error',
                 :locals => {:error => I18n.t('mark.error.save') + result_mark.errors.full_messages.join}
      else
          m_logger.log("User '#{current_user.user_name}' updated mark for submission (id: " +
                       "#{submission.id}) of assignment '#{assignment.short_identifier}' for group" +
                       " '#{group.group_name}'.", MarkusLogger::INFO)
          render :partial => 'results/marker/update_mark',
                 :locals => { :result_mark => result_mark, :mark_value => result_mark.mark}
      end
    end
  end

  def view_marks
    @assignment = Assignment.find(params[:assignment_id])
    @grouping = current_user.accepted_grouping_for(@assignment.id)

    if @grouping.nil?
      redirect_to :controller => 'assignments',
                  :action => 'student_interface',
                  :id => params[:id]
      return
    end
    if !@grouping.has_submission?
      render 'results/student/no_submission'
      return
    end
    @submission = @grouping.current_submission_used
    if !@submission.has_result?
      render 'results/student/no_result'
      return
    end

    @result = @submission.result
    @old_result = nil
    if @submission.remark_submitted?
      @old_result = @result
      @result = @submission.remark_result
      # if remark result's marking state is 'unmarked' then the student has
      # saved a remark request but not submitted it yet, therefore, still editable
      if (@result.marking_state != Result::MARKING_STATES[:unmarked] && !@result.released_to_students)
        render 'results/student/no_remark_result'
        return
      end
    end

    if !@result.released_to_students
      render 'results/student/no_result'
      return
    end

    @annotation_categories = @assignment.annotation_categories
    @group = @grouping.group
    @files = @submission.submission_files
    @test_result_files = @submission.test_results
    @first_file = @files.first
    @extra_marks_points = @result.extra_marks.points
    @extra_marks_percentage = @result.extra_marks.percentage
    @marks_map = Hash.new
    @old_marks_map = Hash.new
    @mark_criteria = @assignment.get_criteria
    @assignment.get_criteria.each do |criterion|
      mark = criterion.marks.find_or_create_by_result_id(@result.id)
      mark.save(:validate => false)
      @marks_map[criterion.id] = mark

      if @old_result
        oldmark = criterion.marks.find_or_create_by_result_id(@old_result.id)
        oldmark.save(false)
        @old_marks_map[criterion.id] = oldmark
      end
    end
    m_logger = MarkusLogger.instance
    m_logger.log("Student '#{current_user.user_name}' viewed results for assignment " +
                 "'#{@assignment.short_identifier}'.")
  end

  def add_extra_mark
    @result = Result.find(params[:id])
    if request.post?
      @extra_mark = ExtraMark.new
      @extra_mark.result = @result
      @extra_mark.unit = ExtraMark::UNITS[:points]
      if !@extra_mark.update_attributes(params[:extra_mark])
        render :template => 'results/marker/add_extra_mark_error'
      else
        # need to re-calculate total mark
        @result.update_total_mark
        render :template => 'results/marker/insert_extra_mark'
      end
      return
    end
    render :template => 'results/marker/add_extra_mark'
  end

  #Deletes an extra mark from the database and removes it from the html
  def remove_extra_mark
    #find the extra mark and destroy it
    @extra_mark = ExtraMark.find(params[:id])
    @extra_mark.destroy
    #need to recalculate total mark
    @result = @extra_mark.result
    @result.update_total_mark
    render :template => 'results/marker/remove_extra_mark'
  end

  def update_overall_comment
    @result = Result.find(params[:id])
    @result.overall_comment = params[:result][:overall_comment]
    @result.save
  end

  def update_overall_remark_comment
    @result = Result.find(params[:id])
    @result.overall_comment = params[:result][:overall_comment]
    @result.save
  end

  def update_remark_request
    @assignment = Assignment.find(params[:assignment_id])
    if !@assignment.past_remark_due_date?
      @submission = Submission.find(params[:id])
      @submission.remark_request = params[:submission][:remark_request]
      @submission.remark_request_timestamp = Time.now
      @submission.save
      @old_result = @submission.result
      if !(@submission.remark_result)
        @submission.create_remark_result_object
      end
      if (params[:real_commit] == "Submit")
        @result = @submission.remark_result
        @result.marking_state = Result::MARKING_STATES[:partial]
        @old_result.released_to_students = (params[:value] == 'false')
        @result.save
        @old_result.save
      end
    end
  end

  def cancel_remark_request
    @submission = Submission.find(params[:submission_id])

    @remark_result = @submission.remark_result
    @remark_result.submission_id = nil
    @remark_result.save

    @submission.remark_result_id = nil
    @submission.remark_request = nil
    @submission.save

    @result = @submission.result
    @result.released_to_students = true
    @result.save

    redirect_to :controller => 'results',
                :action => 'view_marks',
                :id => params[:id]
  end

  def expand_criteria
    @assignment = Assignment.find(params[:assignment_id])
    @mark_criteria = @assignment.get_criteria
    render :partial => 'results/marker/expand_criteria',
           :locals => {:mark_criteria => @mark_criteria}
  end

  def collapse_criteria
    @assignment = Assignment.find(params[:assignment_id])
    @mark_criteria = @assignment.get_criteria
    render :partial => 'results/marker/collapse_criteria', :locals => {:mark_criteria => @mark_criteria}
  end

  def expand_unmarked_criteria
    @assignment = Assignment.find(params[:assignment_id])
    @result = Result.find(params[:id])
    # nil_marks are the marks that have a "nil" value for Mark.mark - so they're
    # unmarked.
    @nil_marks = @result.marks.all(:conditions => {:mark => nil})
    render :partial => 'results/marker/expand_unmarked_criteria', :locals => {:nil_marks => @nil_marks}
  end

  def delete_grace_period_deduction
    @grouping = Grouping.find(params[:id])
    grace_deduction = GracePeriodDeduction.find(params[:deduction_id])
    grace_deduction.destroy
  end

  private


  #Return true if select_file_id matches the id of a file submitted by the
  #current_user. This is to prevent students from downloading files that they
  #or their group have not submitted. Return false otherwise.
  def authorized_to_download?(select_file_id)
    #If the user is a ta or admin, return true as they are authorized.
    if current_user.admin? || current_user.ta?
      return true
    end
    sub_file = SubmissionFile.find_by_id(select_file_id)
    if !sub_file.nil?
      #Check that current_user is in fact in grouping that sub_file belongs to
      return !sub_file.submission.grouping.accepted_students.find(current_user).nil?
    end
    return false
  end
end
