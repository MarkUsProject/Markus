require 'fastercsv'

class SubmissionsController < ApplicationController
  include SubmissionsHelper
  include PaginationHelper
  
  before_filter    :authorize_only_for_admin, :except => [:populate_file_manager, :browse,
  :index, :file_manager, :update_files, 
  :download, :s_table_paginate, :collect_and_begin_grading, 
  :manually_collect_and_begin_grading, :repo_browser, :populate_repo_browser]
  before_filter    :authorize_for_ta_and_admin, :only => [:browse, :index, :s_table_paginate, :collect_and_begin_grading, 
  :manually_collect_and_begin_grading, :repo_browser, :populate_repo_browser]
  before_filter    :authorize_for_student, :only => [:file_manager, :populate_file_manager, :update_files]
  before_filter    :authorize_for_user, :only => [:download]
  
  S_TABLE_PARAMS = {
    :model => Grouping, 
    :per_pages => [15, 30, 50, 100, 150],
    :filters => {
      'none' => {
        :display => I18n.t("browse_submissions.show_all"),
        :proc => lambda { |params|
          return params[:assignment].groupings(:include => [{:student_memberships => :user, :ta_memberships => :user}, :groups, {:submissions => {:results => [:marks, :extra_marks]}}])}},
      'unmarked' => {
        :display => I18n.t("browse_submissions.show_unmarked"), 
        :proc => lambda { |params| return params[:assignment].groupings.select{|g| !g.has_submission? || (g.has_submission? && g.get_submission_used.result.marking_state == Result::MARKING_STATES[:unmarked]) } }},
      'partial' => {
        :display => I18n.t("browse_submissions.show_partial"),
        :proc => lambda { |params| return params[:assignment].groupings.select{|g| g.has_submission? && g.get_submission_used.result.marking_state == Result::MARKING_STATES[:partial] } }},
      'complete' => {
        :display => I18n.t("browse_submissions.show_complete"),
        :proc => lambda { |params| return params[:assignment].groupings.select{|g| g.has_submission? && g.get_submission_used.result.marking_state == Result::MARKING_STATES[:complete] } }},
      'released' => {
        :display => I18n.t("browse_submissions.show_released"),
        :proc => lambda { |params| return params[:assignment].groupings.select{|g| g.has_submission? && g.get_submission_used.result.released_to_students} }},
      'assigned' => {
        :display => I18n.t("browse_submissions.show_assigned_to_me"),
        :proc => lambda { |params| return params[:assignment].ta_memberships.find_all_by_user_id(params[:user_id]).collect{|m| m.grouping} }}
    },
    :sorts => {
      'group_name' => lambda { |a,b| a.group.group_name.downcase <=> b.group.group_name.downcase},
      'repo_name' => lambda { |a,b| a.group.repo_name.downcase <=> b.group.repo_name.downcase },
      'revision_timestamp' => lambda { |a,b|
        return -1 if !a.has_submission?
        return 1 if !b.has_submission?
        return a.get_submission_used.revision_timestamp <=> b.get_submission_used.revision_timestamp
      },
      'marking_state' => lambda { |a,b|
        return -1 if !a.has_submission?
        return 1 if !b.has_submission?
        return a.get_submission_used.result.marking_state <=> b.get_submission_used.result.marking_state
      },
      'total_mark' => lambda { |a,b|
        return -1 if !a.has_submission?
        return 1 if !b.has_submission?
        return a.get_submission_used.result.total_mark <=> b.get_submission_used.result.total_mark
      },
      'grace_credits_used' => lambda { |a,b|
        return a.grace_period_deduction_sum <=> b.grace_period_deduction_sum
      }
    }
  }
        
  def repo_browser
    @grouping = Grouping.find(params[:id])
    @assignment = @grouping.assignment
    @path = params[:path] || '/'
    @previous_path = File.split(@path).first
    @repository_name = @grouping.group.repository_name
    repo = @grouping.group.repo
    begin
      if !params[:revision_timestamp].nil?
        @revision_number = repo.get_revision_by_timestamp(Time.parse(params[:revision_timestamp])).revision_number
      elsif !params[:revision_number].nil?
        @revision_number = params[:revision_number].to_i
      else
        @revision_number = repo.get_latest_revision.revision_number
      end
      @revision = repo.get_revision(@revision_number)
      @revision_timestamp = @revision.timestamp
      repo.close
    rescue Exception => e
      flash[:error] = e.message
      @revision_number = repo.get_latest_revision.revision_number
      @revision_timestamp = repo.get_latest_revision.timestamp
      repo.close
    end
  end
  
  def populate_repo_browser
    @grouping = Grouping.find(params[:id])
    @assignment = @grouping.assignment
    @path = params[:path] || '/'
    @revision_number = params[:revision_number]
    @previous_path = File.split(@path).first
    @grouping.group.access_repo do |repo|
      begin
        @revision = repo.get_revision(params[:revision_number].to_i)
        @directories = @revision.directories_at_path(File.join(@assignment.repository_folder, @path))
        @files = @revision.files_at_path(File.join(@assignment.repository_folder, @path))
      rescue Exception => @find_revision_error
        render :action => 'repo_browser/find_revision_error'
        return
      end
      @table_rows = {}
      @files.sort.each do |file_name, file|
        @table_rows[file.id] = construct_repo_browser_table_row(file_name, file)
      end
      @directories.sort.each do |directory_name, directory|
        @table_rows[directory.id] = construct_repo_browser_directory_table_row(directory_name, directory)
      end
      render :action => 'repo_browser/populate_repo_browser'
    end
  end
 
  def file_manager
    @assignment = Assignment.find(params[:id])

    @grouping = current_user.accepted_grouping_for(@assignment.id)

    if @grouping.nil?
      redirect_to :controller => 'assignments', :action => 'student_interface', :id => params[:id]
      return
    end

    user_group = @grouping.group
    @path = params[:path] || '/'
    
    user_group.access_repo do |repo|
      @revision = repo.get_latest_revision
      @files = @revision.files_at_path(File.join(@assignment.repository_folder, @path))
      @missing_assignment_files = []
      @assignment.assignment_files.each do |assignment_file|
        if !@revision.path_exists?(File.join(@assignment.repository_folder,
        assignment_file.filename))
          @missing_assignment_files.push(assignment_file)
        end
      end
    end
  end
  
  def populate_file_manager
    @assignment = Assignment.find(params[:id])
    @grouping = current_user.accepted_grouping_for(@assignment.id)   
    user_group = @grouping.group
    revision_number= params[:revision_number]
    @path = params[:path] || '/'
    @previous_path = File.split(@path).first
    
    user_group.access_repo do |repo|
      if revision_number.nil?
        @revision = repo.get_latest_revision
      else
       @revision = repo.get_revision(revision_number.to_i)
      end
      @directories = @revision.directories_at_path(File.join(@assignment.repository_folder, @path))
      @files = @revision.files_at_path(File.join(@assignment.repository_folder, @path))
      @table_rows = {}
      @files.sort.each do |file_name, file|
        @table_rows[file.id] = construct_file_manager_table_row(file_name, file)
      end
      if @grouping.repository_external_commits_only?
        @directories.sort.each do |directory_name, directory|
          @table_rows[directory.id] = construct_file_manager_dir_table_row(directory_name, directory)
        end
      end
      render :action => 'file_manager_populate'
    end
  end
  
  def manually_collect_and_begin_grading
    grouping = Grouping.find(params[:id])
    assignment = grouping.assignment
    revision_number = params[:current_revision_number].to_i
    new_submission = Submission.create_by_revision_number(grouping, revision_number)
    result = new_submission.result
    redirect_to :controller => 'results', :action => 'edit', :id => result.id
  end

  def collect_and_begin_grading
    assignment = Assignment.find(params[:id])
    grouping = Grouping.find(params[:grouping_id])
    if !assignment.submission_rule.can_collect_now?
      flash[:error] = "Could not collect submission for group #{grouping.group.group_name} - the collection date has not been reached yet."
    else
      time = assignment.submission_rule.calculate_collection_time.localtime
      # Create a new Submission by timestamp.
      # A Result is automatically attached to this Submission, thanks to some callback
      # logic inside the Submission model
      begin
        new_submission = Submission.create_by_timestamp(grouping, time)
      # Apply the SubmissionRule
        new_submission = assignment.submission_rule.apply_submission_rule(new_submission)
        result = new_submission.result
        redirect_to :controller => 'results', :action => 'edit', :id => result.id
        return
      rescue Exception => e
        flash[:error] = e.message
      end
    end
    redirect_to :action => 'browse', :id => assignment.id
  end


  def browse
    if current_user.ta?
      params[:filter] = 'assigned'    
    else
      if params[:filter] == nil or params[:filter].blank?
        params[:filter] = 'none'    
      end
    end
    if params[:sort_by] == nil or params[:sort_by].blank?
      params[:sort_by] = 'group_name'
    end 
    @assignment = Assignment.find(params[:id])
    @groupings, @groupings_total = handle_paginate_event(
      S_TABLE_PARAMS,                                     # the data structure to handle filtering and sorting
        { :assignment => @assignment,                     # the assignment to filter by
          :user_id => current_user.id},                   # the submissions accessable by the current user
      params)                                             # additional parameters that affect things like sorting
    @current_page = params[:page].to_i()
    @per_page = params[:per_page]
    @filters = get_filters(S_TABLE_PARAMS)
    @per_pages = S_TABLE_PARAMS[:per_pages]
    @desc = params[:desc]
    @filter = params[:filter]
    @sort_by = params[:sort_by]
  end 

  def index
    @assignments = Assignment.all(:order => :id)
    render :action => 'index', :layout => 'sidebar'
  end

  # controller handles transactional submission of files
  def update_files
    assignment_id = params[:id]
    assignment = Assignment.find(assignment_id)
    path = params[:path] || '/'
    grouping = current_user.accepted_grouping_for(assignment_id)
    if grouping.repository_external_commits_only?
      raise "MarkUs is only accepting external submits"
    end
    if !grouping.is_valid?
      redirect_to :action => :file_manager, :id => assignment_id
      return
    end
    grouping.group.access_repo do |repo|

      assignment_folder = File.join(assignment.repository_folder, path)

      # Get the revision numbers for the files that we've seen - these
      # values will be the "expected revision numbers" that we'll provide
      # to the transaction to ensure that we don't overwrite a file that's
      # been revised since the user last saw it.
      file_revisions = params[:file_revisions].nil? ? [] : params[:file_revisions]

      # The files that will be replaced - just give an empty array
      # if params[:replace_files] is nil
      replace_files = params[:replace_files].nil? ? {} : params[:replace_files]

      # The files that will be deleted
      delete_files = params[:delete_files].nil? ? {} : params[:delete_files]

      # The files that will be added
      new_files = params[:new_files].nil? ? {} : params[:new_files]

      # Create transaction, setting the author.  Timestamp is implicit.
      txn = repo.get_transaction(current_user.user_name)

      log_messages = []
      begin
        # delete files marked for deletion
        delete_files.keys.each do |filename|
          txn.remove(File.join(assignment_folder, filename), file_revisions[filename])
          log_messages.push(I18n.t("markus_logger.student_deleted_file", :user_name => current_user.user_name, :file_name => filename, :assignment => assignment.short_identifier))
        end

        # Replace files
        replace_files.each do |filename, file_object|
          # Sometimes the file pointer of file_object is at the end of the file.
          # In order to avoid empty uploaded files, rewind it to be save.
          file_object.rewind
          txn.replace(File.join(assignment_folder, filename), file_object.read, file_object.content_type, file_revisions[filename])
          log_messages.push(I18n.t("markus_logger.student_replaced_file", :user_name => current_user.user_name, :file_name => filename, :assignment => assignment.short_identifier))
        end

        # Add new files
        new_files.each do |file_object|
          # sanitize_file_name in SubmissionsHelper
          if file_object.original_filename.nil?
            raise "Invalid file name on submitted file"
          end
          # Sometimes the file pointer of file_object is at the end of the file.
          # In order to avoid empty uploaded files, rewind it to be save.
          file_object.rewind
          txn.add(File.join(assignment_folder, sanitize_file_name(file_object.original_filename)), file_object.read, file_object.content_type)
          log_messages.push(I18n.t("markus_logger.student_submitted_file", :user_name => current_user.user_name, :file_name => file_object.original_filename, :assignment => assignment.short_identifier))
        end

        # finish transaction
        if !txn.has_jobs?
          flash[:transaction_warning] = I18n.t("student.submission.no_action_detected")
          redirect_to :action => "file_manager", :id => assignment_id
          return
        end
        if !repo.commit(txn)
          flash[:update_conflicts] = txn.conflicts
        else
          flash[:success] = I18n.t('update_files.success')
          # flush log messages
          m_logger = MarkusLogger.instance
          log_messages.each do |msg|
            m_logger.log(msg)
          end
        end

        # Are we past collection time?
        if assignment.submission_rule.can_collect_now?
          flash[:commit_notice] = assignment.submission_rule.commit_after_collection_message(grouping)
        end
        redirect_to :action => "file_manager", :id => assignment_id

      rescue Exception => e
        raise e
        flash[:commit_error] = e.message
        redirect_to :action => "file_manager", :id => assignment_id
      end
    end
  end
  
  def download
    @assignment = Assignment.find(params[:id])
    # find_appropriate_grouping can be found in SubmissionsHelper

    @grouping = find_appropriate_grouping(@assignment.id, params)

    revision_number = params[:revision_number]
    path = params[:path] || '/'
    @grouping.group.access_repo do |repo|
      if revision_number.nil?
        @revision = repo.get_latest_revision
      else
        @revision = repo.get_revision(revision_number.to_i)
      end

      begin
       file = @revision.files_at_path(File.join(@assignment.repository_folder, path))[params[:file_name]]
       file_contents = repo.download_as_string(file)
      rescue Exception => e
        render :text => "Could not download #{params[:file_name]}: #{e.message}.  File may be missing."
        return
      end
    
      if SubmissionFile.is_binary?(file_contents)
        # If the file appears to be binary, send it as a download
        send_data file_contents, :disposition => 'attachment', :filename => params[:file_name]
      else
        # Otherwise, blast it out to the screen
        render :text => file_contents, :layout => 'sanitized_html'
      end
    end
  end 

  def update_submissions
    return unless request.post?
    assignment = Assignment.find(params[:id])
    errors = []
    groupings = []
    if params[:ap_select_full] == 'true'
      # We should have been passed a filter
      if params[:filter].blank?
        raise "Expected a filter on select full"
      end
      # Get all Groupings for this filter
      groupings = S_TABLE_PARAMS[:filters][params[:filter]][:proc].call({:assignment => assignment, :user_id => current_user.id})
    else
      # User selected particular Grouping IDs
      if params[:groupings].nil?
        errors.push(I18n.t('results.must_select_a_group'))
      else
        groupings = assignment.groupings.find(params[:groupings])
      end
    end

    log_message = ""       
    if !params[:release_results].nil?
      changed = set_release_on_results(groupings, true, errors)
      log_message = I18n.t("markus_logger.marks_released_for_assignment",
                            :assignment_id => assignment.id,
                            :assignment => assignment.short_identifier,
                            :number_groups => changed)
    elsif !params[:unrelease_results].nil?
      changed = set_release_on_results(groupings, false, errors)
      log_message = I18n.t("markus_logger.marks_unreleased_for_assignment",
                            :assignment_id => assignment.id,
                            :assignment => assignment.short_identifier,
                            :number_groups => changed)
    end


    if !groupings.empty?
      assignment.set_results_average
    end

    if changed > 0
      flash[:success] = I18n.t('results.successfully_changed', {:changed => changed})
      m_logger = MarkusLogger.instance
      m_logger.log(log_message)
    end
    flash[:errors] = errors
    
    redirect_to :action => 'browse', :id => params[:id]    
  end
  
  def unrelease
    return unless request.post?
    if params[:groupings].nil?
      flash[:release_results] = "Select a group"
    else
      params[:groupings].each do |g|
        g.unrelease_results
      end
      m_logger = MarkusLogger.instance
      assignment = Assignment.find(params[:id])
      m_logger.log(I18n.t("markus_logger.marks_unreleased_for_assignment",
                  :assignment_id => assignment.id,
                  :assignment => assignment.short_identifier,
                  :number_groups => params[:groupings].length))
    end
    redirect_to :action => 'browse', :id => params[:id]
  end
  
  # See Assignment.get_simple_csv_report for details
  def download_simple_csv_report
    assignment = Assignment.find(params[:id])
    send_data assignment.get_simple_csv_report, :disposition => 'attachment', :type => 'application/vnd.ms-excel', :filename => "#{assignment.short_identifier} simple report.csv"
  end
  
  # See Assignment.get_detailed_csv_report for details
  def download_detailed_csv_report
    assignment = Assignment.find(params[:id])
    send_data assignment.get_detailed_csv_report, :disposition => 'attachment', :type => 'application/vnd.ms-excel', :filename => "#{assignment.short_identifier} detailed report.csv"
  end
  
  # See Assignment.get_svn_export_commands for details
  def download_svn_export_commands
    assignment = Assignment.find(params[:id])
    svn_commands = assignment.get_svn_export_commands
    send_data svn_commands.join("\n"), :disposition => 'attachment', :type => 'text/plain', :filename => "#{assignment.short_identifier}_svn_exports"
  end

  # See Assignment.get_svn_repo_list for details
  def download_svn_repo_list
    assignment = Assignment.find(params[:id])
    send_data assignment.get_svn_repo_list, :disposition => 'attachment', :type => 'text/plain', :filename => "#{assignment.short_identifier}_svn_repo_list"
  end

end
