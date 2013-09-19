include CsvHelper
require 'zip/zip'

class SubmissionsController < ApplicationController
  include SubmissionsHelper
  include PaginationHelper

  before_filter :authorize_only_for_admin,
                :except => [:server_time,
                            :populate_file_manager,
                            :browse,
                            :index,
                            :file_manager,
                            :update_files,
                            :download,
                            :downloads,
                            :s_table_paginate,
                            :collect_and_begin_grading,
                            :download_groupings_files,
                            :manually_collect_and_begin_grading,
                            :collect_ta_submissions,
                            :repo_browser,
                            :populate_repo_browser,
                            :update_converted_pdfs,
                            :update_submissions]
  before_filter :authorize_for_ta_and_admin,
                :only => [:browse,
                          :index,
                          :s_table_paginate,
                          :collect_and_begin_grading,
                          :manually_collect_and_begin_grading,
                          :collect_ta_submissions,
                          :repo_browser,
                          :download_groupings_files,
                          :populate_repo_browser,
                          :update_converted_pdfs,
                          :update_submissions]
  before_filter :authorize_for_student,
                :only => [:file_manager,
                          :populate_file_manager,
                          :update_files]
  before_filter :authorize_for_user, :only => [:download, :downloads]

  # TABLE FOR TAs
  TA_TABLE_PARAMS = {
    :model => Grouping,
    :per_pages => [15, 30, 50, 100, 150, 500, 1000],
    :filters => {
      'none' => {
        :display => I18n.t('browse_submissions.show_all'),
        :proc => lambda { |params, to_include|
          params[:assignment].ta_memberships.find_all_by_user_id(
              params[:user_id], :include => [:grouping => to_include]).
              collect { |m| m.grouping }
        }
      },
      'unmarked' => {
        :display => I18n.t('browse_submissions.show_unmarked'),
        :proc => lambda { |params, to_include| 
           (params[:assignment].ta_memberships.find_all_by_user_id(
               params[:user_id], :include => [:grouping => to_include]).
               collect{|m| m.grouping}
           ).select { |g| !g.has_submission? || (g.has_submission? &&
                   g.current_submission_used.get_latest_result.marking_state ==
                       Result::MARKING_STATES[:unmarked]) }}
      },
      
      'partial' => {
        :display => I18n.t('browse_submissions.show_partial'),
        :proc => lambda { |params, to_include| 
           (params[:assignment].ta_memberships.find_all_by_user_id(
                    params[:user_id], :include => [:grouping => to_include]).
               collect{|m| m.grouping}
           ).select{ |g| g.has_submission? &&
               g.current_submission_used.get_latest_result.marking_state ==
                   Result::MARKING_STATES[:partial]} }
      },
      
      'complete' => {
        :display => I18n.t('browse_submissions.show_complete'),
        :proc => lambda{ |params, to_include| 
          (params[:assignment].ta_memberships.find_all_by_user_id(
              params[:user_id], :include => [:grouping => to_include]).
              collect{|m| m.grouping}
          ).select{|g| g.has_submission? &&
              g.current_submission_used.get_latest_result.marking_state ==
                  Result::MARKING_STATES[:complete]} }
      },
      
      'released' => {
        :display => I18n.t('browse_submissions.show_released'),
        :proc => lambda{ |params, to_include| 
          (params[:assignment].ta_memberships.find_all_by_user_id(
              params[:user_id], :include => [:grouping => to_include]).
              collect{|m| m.grouping}
          ).select{|g| g.has_submission? &&
              g.current_submission_used.get_latest_result.released_to_students}}
      },
      
      'assigned' => {
        :display => I18n.t('browse_submissions.show_assigned_to_me'),
        :proc => lambda { |params, to_include|
          params[:assignment].ta_memberships.find_all_by_user_id(
              params[:user_id], :include => [:grouping => to_include]).
              collect{|m| m.grouping} }}
    },
    
    :sorts => {
      'group_name' => lambda { |a,b| a.group.group_name.downcase <=>
        b.group.group_name.downcase},
      'repo_name' => lambda { |a,b| a.group.repo_name.downcase <=>
          b.group.repo_name.downcase },
      'revision_timestamp' => lambda { |a,b|
        ret = -1 if !a.has_submission?
        ret ||= 1 if !b.has_submission?
        ret ||= a.current_submission_used.revision_timestamp <=>
            b.current_submission_used.revision_timestamp
      },
      'marking_state' => lambda { |a,b|
        ret = -1 if !a.has_submission?
        ret ||= 1 if !b.has_submission?
        ret ||= a.current_submission_used.get_latest_result.marking_state <=>
            b.current_submission_used.get_latest_result.marking_state
      },
      'total_mark' => lambda { |a,b|
        ret = -1 if !a.has_submission?
        ret ||= 1 if !b.has_submission?
        ret ||= a.current_submission_used.get_latest_result.total_mark <=>
            b.current_submission_used.get_latest_result.total_mark
      },
      'grace_credits_used' => lambda { |a,b|
        a.grace_period_deduction_single <=> b.grace_period_deduction_single
      },
      'section' => lambda { |a,b|
        ret = -1 if !a.section
        ret ||= 1 if !b.section
        ret ||= a.section <=> b.section
      }
    }
  }
  
  # TABLE FOR Admin
  ADMIN_TABLE_PARAMS = {
    :model => Grouping,
    :per_pages => [15, 30, 50, 100, 150, 500, 1000],
    :filters => {
      'none' => {
        :display => I18n.t('browse_submissions.show_all'),
        :proc => lambda { |params, to_include|
          params[:assignment].groupings.all(:include => to_include)}},
      'unmarked' => {
        :display => I18n.t('browse_submissions.show_unmarked'),
        :proc => lambda { |params, to_include|
          params[:assignment].groupings.all(:include => [to_include]).
              select{|g| !g.has_submission? || (g.has_submission? &&
              g.current_submission_used.get_latest_result.marking_state ==
                  Result::MARKING_STATES[:unmarked]) } }},
      'partial' => {
        :display => I18n.t('browse_submissions.show_partial'),
        :proc => lambda { |params, to_include|
          params[:assignment].groupings.all(:include => [to_include]).
              select{|g| g.has_submission? &&
              g.current_submission_used.get_latest_result.marking_state ==
                  Result::MARKING_STATES[:partial] } }},
      'complete' => {
        :display => I18n.t('browse_submissions.show_complete'),
        :proc => lambda { |params, to_include|
          params[:assignment].groupings.all(:include => [to_include]).
              select{|g| g.has_submission? &&
              g.current_submission_used.get_latest_result.marking_state ==
                  Result::MARKING_STATES[:complete] } }},
      'released' => {
        :display => I18n.t('browse_submissions.show_released'),
        :proc => lambda { |params, to_include|
          params[:assignment].groupings.all(:include => [to_include]).
              select{|g| g.has_submission? &&
              g.current_submission_used.get_latest_result.released_to_students}}},
      'assigned' => {
        :display => I18n.t('browse_submissions.show_assigned_to_me'),
        :proc => lambda { |params, to_include|
          params[:assignment].ta_memberships.find_all_by_user_id(
              params[:user_id], :include => [:grouping => to_include]).
              collect{|m| m.grouping} }}
    },
    :sorts => {
      'group_name' => lambda { |a,b|
        a.group.group_name.downcase <=> b.group.group_name.downcase},
      'repo_name' => lambda { |a,b|
        a.group.repo_name.downcase <=> b.group.repo_name.downcase },
      'revision_timestamp' => lambda { |a,b|
        ret = -1 if !a.has_submission?
        ret ||= 1 if !b.has_submission?
        ret ||= a.current_submission_used.revision_timestamp <=>
            b.current_submission_used.revision_timestamp
      },
      # Ordering for marking state: 
      #   Released (icon: "sent mail") - complete & released_to_student
      #   Complete (icon: green circle check mark) - complete
      #   Remark Requested (icon: speech bubble exclamation mark) - partial & remark_submitted
      #   Partial (icon: pencil) - partial
      #   Unmarked (icon : pencil) - unmarked
      'marking_state' => lambda { |a,b|
        if !a.has_submission? || a.current_submission_used.
            get_latest_result.released_to_students
          -1
        elsif !b.has_submission? || b.current_submission_used.
            get_latest_result.released_to_students
          1
        elsif a.current_submission_used.get_latest_result.marking_state ==
            Result::MARKING_STATES[:partial] && b.current_submission_used.
            get_latest_result.marking_state == Result::MARKING_STATES[:partial]
          ret ||= -1 if a.current_submission_used.remark_submitted?
          ret ||= 1 if b.current_submission_used.remark_submitted?
          ret ||= 0
        else
          a.current_submission_used.get_latest_result.marking_state <=>
              b.current_submission_used.get_latest_result.marking_state
        end
      },
      'total_mark' => lambda { |a,b|
        ret = -1 if !a.has_submission?
        ret ||= 1 if !b.has_submission?
        ret ||= a.current_submission_used.get_latest_result.total_mark <=>
          b.current_submission_used.get_latest_result.total_mark
      },
      'grace_credits_used' => lambda { |a,b|
        a.grace_period_deduction_single <=> b.grace_period_deduction_single
      },
      'section' => lambda { |a,b|
        ret = -1 if !a.section
        ret ||= 1 if !b.section
        ret ||= a.section <=> b.section
      }
    }
  }

  def repo_browser
    @assignment = Assignment.find(params[:assignment_id])
    @grouping = Grouping.find(params[:id])
    @assignment = @grouping.assignment
    @path = params[:path] || '/'
    @previous_path = File.split(@path).first
    @repository_name = @grouping.group.repository_name
    repo = @grouping.group.repo
    begin
      if params[:revision_timestamp]
        @revision_number = repo.get_revision_by_timestamp(Time.parse(params[:revision_timestamp])).revision_number
      elsif params[:revision_number]
        @revision_number = params[:revision_number].to_i
      else
        @revision_number = repo.get_latest_revision.revision_number
      end
      @revision = repo.get_revision(@revision_number)
      @revision_timestamp = @revision.timestamp
    rescue Exception => e
      flash[:error] = e.message
      @revision_number = repo.get_latest_revision.revision_number
      @revision_timestamp = repo.get_latest_revision.timestamp
    end
    # generate an revisions' history with date and num
    @revisions_history = []
    rev_number = repo.get_latest_revision.revision_number + 1
    rev_number.times.each do |rev|
      begin
        revision = repo.get_revision(rev)
        unless revision.path_exists?(
            File.join(@assignment.repository_folder, @path))
          raise 'error'
        end
      rescue Exception
        revision = nil
      end
      if revision
        @revisions_history << {:num => revision.revision_number,
                               :date => revision.timestamp}
      end
    end
    repo.close
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
        render :template => 'submissions/repo_browser/find_revision_error'
        return
      end
      @table_rows = {}
      @files.sort.each do |file_name, file|
        @table_rows[file.object_id] = construct_repo_browser_table_row(file_name, file)
      end
      @directories.sort.each do |directory_name, directory|
        @table_rows[directory.object_id] = construct_repo_browser_directory_table_row(directory_name, directory)
      end
      render :template => 'submissions/repo_browser/populate_repo_browser'
    end
  end

  def file_manager
    @assignment = Assignment.find(params[:assignment_id])
    @grouping = current_user.accepted_grouping_for(@assignment.id)

    if @grouping.nil?
      redirect_to :controller => 'assignments',
                  :action => 'student_interface',
                  :id => params[:id]
      return
    end

    user_group = @grouping.group
    @path = params[:path] || '/'

    # Some vars need to be set in update_files too, so do this in a
    # helper. See update_files action where this is used as well.
    set_filebrowser_vars(user_group, @assignment)
  end

  def populate_file_manager
    @assignment = Assignment.find(params[:assignment_id])
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
        @table_rows[file.object_id] = construct_file_manager_table_row(file_name, file)
      end
      if @grouping.repository_external_commits_only?
        @directories.sort.each do |directory_name, directory|
          @table_rows[directory.object_id] = construct_file_manager_dir_table_row(directory_name, directory)
        end
      end
      render :file_manager_populate
    end
  end

  def manually_collect_and_begin_grading
    @grouping = Grouping.find(params[:id])
    @revision_number = params[:current_revision_number].to_i
    SubmissionCollector.instance.manually_collect_submission(@grouping,
      @revision_number)
    redirect_to :action => 'update_converted_pdfs', :id => @grouping.id
  end

  def collect_and_begin_grading
    
    assignment = Assignment.find(params[:assignment_id])
    grouping = Grouping.find(params[:id])
    
    if assignment.submission_rule.can_collect_grouping_now?(grouping)
      #Push grouping to the priority queue
      SubmissionCollector.instance.push_grouping_to_priority_queue(grouping)
      flash[:success] = I18n.t('collect_submissions.priority_given')
    else
      flash[:error] = I18n.t('browse_submissions.could_not_collect',
                             :group_name => grouping.group.group_name)
    end
    redirect_to :action   => 'browse', 
                :id       => assignment.id
  end

  def collect_all_submissions
    assignment = Assignment.find(params[:assignment_id], :include => [:groupings])
    if assignment.submission_rule.can_collect_now?
      submission_collector = SubmissionCollector.instance
      submission_collector.push_groupings_to_queue(assignment.groupings)
      flash[:success] = I18n.t('collect_submissions.collection_job_started',
                               :assignment_identifier => assignment.short_identifier)
    else
      flash[:error] = I18n.t('collect_submissions.could_not_collect',
                             :assignment_identifier => assignment.short_identifier)
    end
    redirect_to :action => 'browse', 
                :id => assignment.id
  end

  def collect_ta_submissions
    assignment = Assignment.find(params[:assignment_id])
    if assignment.submission_rule.can_collect_now?
      groupings = assignment.groupings.all(:include => :tas,
                                           :conditions => ['users.id = ?',
                                                           current_user.id])
      submission_collector = SubmissionCollector.instance
      submission_collector.push_groupings_to_queue(groupings)
      flash[:success] = I18n.t('collect_submissions.collection_job_started',
                               :assignment_identifier => assignment.short_identifier)
    else
      flash[:error] = I18n.t('collect_submissions.could_not_collect',
                             :assignment_identifier => assignment.short_identifier)
    end
    redirect_to :action => 'browse',
                :id => assignment.id
  end

  def update_converted_pdfs
    @grouping = Grouping.find(params[:grouping_id])
    @submission = @grouping.current_submission_used
    @pdf_count= 0
    @converted_count = 0
    unless @submission.nil?
      @submission.submission_files.each do |file|
        if file.is_pdf?
          @pdf_count += 1
          if file.is_converted
            @converted_count += 1
          end
        end
      end
    end
  end

  def browse

    if params[:filter].blank?
      params[:filter] = 'none'
    end

    @assignment = Assignment.find(params[:assignment_id])
    
    @c_per_page = current_user.id.to_s + '_' + @assignment.id.to_s + '_per_page'
    if params[:per_page].present?
       cookies[@c_per_page] = params[:per_page] 
    elsif cookies[@c_per_page].present?
       params[:per_page] = cookies[@c_per_page]
    end 

    @c_sort_by = current_user.id.to_s + '_' + @assignment.id.to_s + '_sort_by'
    if params[:sort_by].present?
       cookies[@c_sort_by] = params[:sort_by]
    elsif cookies[@c_sort_by].present?
       params[:sort_by] = cookies[@c_sort_by]
    else
       params[:sort_by] = 'group_name' 
    end

    # the data structure to handle filtering and sorting
    # the assignment to filter by
    # the submissions accessible by the current user
    # additional parameters that affect things like sorting
    if current_user.ta?
        @groupings, @groupings_total = handle_paginate_event(
      TA_TABLE_PARAMS,
        { :assignment => @assignment,
          :user_id => current_user.id},
      params)
    else
      @groupings, @groupings_total = handle_paginate_event(
        ADMIN_TABLE_PARAMS,
          { :assignment => @assignment,
            :user_id => current_user.id},
        params)
    end

    #Eager load all data only for those groupings that will be displayed
    sorted_groupings = @groupings
    @groupings = Grouping.all(:conditions => {:id => sorted_groupings},
                              :include =>
                                  [:assignment, :group, :grace_period_deductions,
                                   {:current_submission_used => :results},
                                   {:accepted_student_memberships => :user}])

    #re-sort @groupings by the previous order, because eager loading query
    #messed up the grouping order
    @groupings = sorted_groupings.map do |sorted_grouping|
      @groupings.detect do |unsorted_grouping|
        unsorted_grouping == sorted_grouping
      end
    end
    
    if cookies[@c_per_page].blank?
       cookies[@c_per_page] = params[:per_page]
    end
    
    if cookies[@c_sort_by].blank?
       cookies[@c_sort_by] = params[:sort_by]
    end
 
    @current_page = params[:page].to_i()
    @per_page = cookies[@c_per_page]

    if current_user.ta?
      @filters = get_filters(TA_TABLE_PARAMS)
      @per_pages = TA_TABLE_PARAMS[:per_pages]
    else
      @filters = get_filters(ADMIN_TABLE_PARAMS)
      @per_pages = ADMIN_TABLE_PARAMS[:per_pages]
    end

    @desc = params[:desc]
    @filter = params[:filter]
    @sort_by = cookies[@c_sort_by]
  end

  def index
    @assignments = Assignment.all(:order => :id)
    render :index, :layout => 'sidebar'
  end

  # update_files action handles transactional submission of files.
  #
  # Note that you shouldn't use redirect_to in this action. This
  # is due to @file_manager_errors, which carries over some state
  # to the file_manager view (via render calls). We need to do
  # this, because we were storing transaction errors in the flash
  # hash (i.e. they were stored in the browser's cookie), and in
  # some circumstances, this produces a cookie overflow error
  # when the state stored in the cookie exceeds 4k in serialized
  # form. This was happening prior to the fix of Github issue #30.
  def update_files
    # We'll use this hash to carry over some error state to the
    # file_manager view.
    @file_manager_errors = Hash.new
    assignment_id = params[:assignment_id]
    @assignment = Assignment.find(assignment_id)
    @path = params[:path] || '/'
    @grouping = current_user.accepted_grouping_for(assignment_id)
    if @grouping.repository_external_commits_only?
      raise I18n.t('student.submission.external_submit_only')
    end
    unless @grouping.is_valid?
      # can't use redirect_to here. See comment of this action for more details.
      set_filebrowser_vars(@grouping.group, @assignment)
      render :file_manager, :id => assignment_id
      return
    end
    @grouping.group.access_repo do |repo|

      assignment_folder = File.join(@assignment.repository_folder, @path)

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
          log_messages.push("Student '#{current_user.user_name}' deleted file '#{filename}' for assignment '#{@assignment.short_identifier}'.")
        end

        # Replace files
        replace_files.each do |filename, file_object|
          # Sometimes the file pointer of file_object is at the end of the file.
          # In order to avoid empty uploaded files, rewind it to be save.
          file_object.rewind
          txn.replace(File.join(assignment_folder, filename), file_object.read, file_object.content_type, file_revisions[filename])
          log_messages.push("Student '#{current_user.user_name}' replaced content of file '#{filename}' for assignment '#{@assignment.short_identifier}'.")
        end

        # Add new files
        new_files.each do |file_object|
          # sanitize_file_name in SubmissionsHelper
          if file_object.original_filename.nil?
            raise I18n.t('student.submission.invalid_file_name')
          end
          # Sometimes the file pointer of file_object is at the end of the file.
          # In order to avoid empty uploaded files, rewind it to be save.
          file_object.rewind
          txn.add(File.join(assignment_folder, sanitize_file_name(file_object.original_filename)), file_object.read, file_object.content_type)
          log_messages.push("Student '#{current_user.user_name}' submitted file '#{file_object.original_filename}' for assignment '#{@assignment.short_identifier}'.")
        end

        # finish transaction
        unless txn.has_jobs?
          flash[:transaction_warning] = I18n.t('student.submission.no_action_detected')
          # can't use redirect_to here. See comment of this action for more details.
          set_filebrowser_vars(@grouping.group, @assignment)
          render :file_manager, :id => assignment_id
          return
        end
        if repo.commit(txn)
          flash[:success] = I18n.t('update_files.success')
          # flush log messages
          m_logger = MarkusLogger.instance
          log_messages.each do |msg|
            m_logger.log(msg)
          end
        else
          @file_manager_errors[:update_conflicts] = txn.conflicts
        end

        # Are we past collection time?
        if @assignment.submission_rule.can_collect_now?
          flash[:commit_notice] = @assignment.submission_rule.commit_after_collection_message
        end
        # can't use redirect_to here. See comment of this action for more details.
        set_filebrowser_vars(@grouping.group, @assignment)
        render :file_manager, :id => assignment_id

      rescue Exception => e
        m_logger = MarkusLogger.instance
        m_logger.log(e.message)
        # can't use redirect_to here. See comment of this action for more details.
        @file_manager_errors[:commit_error] = e.message
        set_filebrowser_vars(@grouping.group, @assignment)
        render :file_manager, :id => assignment_id
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
        render :text => I18n.t('student.submission.missing_file', :file_name => params[:file_name], :message => e.message)
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

  ##
  # Download all files from all groupings in a .zip file.
  ##
  def download_groupings_files

    assignment = Assignment.find(params[:assignment_id])

    ## create the zip name with the user name to have less chance to delete
    ## a currently downloading file
    short_id = assignment.short_identifier
    zip_name = short_id + '_' + current_user.user_name + '.zip'
    ## check if there is a '/' in the file name to replace by '_'
    zip_path = 'tmp/' + zip_name.tr('/', '_')

    ## delete the old file if it exists
    File.delete(zip_path) if File.exist?(zip_path)

    grouping_ids = params[:groupings]

    ## if there is no grouping, render a message
    if grouping_ids.blank?
      render :text => t('student.submission.no_groupings_available')
      return
    end

    groupings = Grouping.find(grouping_ids)

    ## build the zip file
    Zip::ZipFile.open(zip_path, Zip::ZipFile::CREATE) do |zip_file|

      groupings.map do |grouping|

        ## retrieve the submitted files
        submission = grouping.current_submission_used
        next unless submission
        files = submission.submission_files

        ## create the grouping directory
        sub_folder = grouping.group.repo_name
        zip_file.mkdir(sub_folder) unless zip_file.find_entry(sub_folder)

        files.each do |file|

          ## retrieve the file and print an error on redirect back if there is
          begin
            file_content = file.retrieve_file
          rescue Exception => e
            flash[:error] = e.message
            redirect_to :back
            return
          end

          ## create the file inside the sub folder
          zip_file.get_output_stream(File.join(sub_folder, file.filename)) do |f|
            f.puts file_content
          end

        end
      end
    end

    ## Send the Zip file
    send_file zip_path, :disposition => 'inline', :filename => zip_name
  end

  ##
  # Download all files from a repository folder in a Zip file.
  ##
  def downloads
    @assignment = Assignment.find(params[:assignment_id])
    @grouping = find_appropriate_grouping(@assignment.id, params)

    revision_number = params[:revision_number]
    repo_folder = @assignment.repository_folder
    full_path = File.join(repo_folder, params[:path] || '/')
    zip_name = "#{repo_folder}-#{@grouping.group.repo_name}"
    @grouping.group.access_repo do |repo|
      @revision = if revision_number.nil?
                    repo.get_latest_revision
                  else
                    repo.get_revision(revision_number.to_i)
                  end
      zip_path = "tmp/#{@assignment.short_identifier}_" +
          "#{@grouping.group.group_name}_r#{@revision.revision_number}.zip"

      if revision_number && revision_number.to_i == 0
        render :text => t('student.submission.no_revision_available')
        return
      end
      # Open Zip file and fill it with all the files in the repo_folder
      Zip::ZipFile.open(zip_path, Zip::ZipFile::CREATE) do |zip_file|

        files = @revision.files_at_path(full_path)
        if files.count == 0
          render :text => t('student.submission.no_files_available')
          return
        end

        files.each do |file|
          begin
            file_contents = repo.download_as_string(file.last)
          rescue Exception => e
            render :text => t('student.submission.missing_file',
                              :file_name => file.first, :message => e.message)
            return
          end

          # Create the folder in the Zip file if it doesn't exist
          zip_file.mkdir(zip_name) unless zip_file.find_entry(zip_name)

          zip_file.get_output_stream(File.join(zip_name, file.first)) do |f|
            f.puts file_contents
          end
        end
      end

      # Send the Zip file
      send_file zip_path, :disposition => 'inline',
                :filename => zip_name + '.zip'
    end
  end

  def update_submissions
    
    return unless request.post?
    assignment = Assignment.find(params[:assignment_id])
    errors = []
    groupings = []
    if params[:ap_select_full] == 'true'
      # We should have been passed a filter
      if params[:filter].blank?
        raise I18n.t('student.submission.expect_filter')
      end
     
      # Get all Groupings for this filter 
      if current_user.ta?
        groupings = TA_TABLE_PARAMS[:filters][params[:filter]][:proc].call({:assignment => assignment, :user_id => current_user.id}, {})
      else
        groupings = ADMIN_TABLE_PARAMS[:filters][params[:filter]][:proc].call({:assignment => assignment, :user_id => current_user.id}, {})
      end
    
    else
      # User selected particular Grouping IDs
      if params[:groupings].nil?
        errors.push(I18n.t('results.must_select_a_group')) unless !params[:collect_section].nil? 
      else
        groupings = assignment.groupings.find(params[:groupings])
      end
    end

    log_message = ''
    if params[:release_results]
      changed = set_release_on_results(groupings, true, errors)
      log_message = "Marks released for assignment '#{assignment.short_identifier}', ID: '" +
                    "#{assignment.id}' (for #{changed} groups)."
    elsif params[:unrelease_results]
      changed = set_release_on_results(groupings, false, errors)
      log_message = "Marks unreleased for assignment '#{assignment.short_identifier}', ID: '" +
                    "#{assignment.id}' (for #{changed} groups)."
    elsif params[:collect_section]
      if params[:section_to_collect] == ''
        errors.push(I18n.t('collect_submissions.must_select_a_section'))
      else
        collected = collect_submissions_for_section(params[:section_to_collect], assignment, errors)
        if collected > 0
          flash[:success] = I18n.t('collect_submissions.successfully_collected', :collected => collected)
        end
      end
    end


    unless groupings.empty?
      assignment.set_results_statistics
    end

    if changed && changed > 0
      flash[:success] = I18n.t('results.successfully_changed', {:changed => changed})
      m_logger = MarkusLogger.instance
      m_logger.log(log_message)
    end
    flash[:errors] = errors

    redirect_to :action => 'browse',
                :id => params[:id],
                :per_page => params[:per_page],
                :filter   => params[:filter],
                :sort_by  => params[:sort_by] 
  end

  def unrelease
    return unless request.post?
    if params[:groupings].nil?
      flash[:release_results] = I18n.t('assignment.group.select_a_group')
    else
      params[:groupings].each do |g|
        g.unrelease_results
      end
      m_logger = MarkusLogger.instance
      assignment = Assignment.find(params[:id])
      m_logger.log("Marks unreleased for assignment '#{assignment.short_identifier}', ID: '" +
                   "#{assignment.id}' (for #{params[:groupings].length} groups).")
    end
    redirect_to :action => 'browse', 
                :id => params[:id]
  end

  # See Assignment.get_simple_csv_report for details
  def download_simple_csv_report
    assignment = Assignment.find(params[:assignment_id])
    send_data assignment.get_simple_csv_report,
              :disposition => 'attachment',
              :type => 'application/vnd.ms-excel',
              :filename => "#{assignment.short_identifier} simple report.csv"
  end

  # See Assignment.get_detailed_csv_report for details
  def download_detailed_csv_report
    assignment = Assignment.find(params[:assignment_id])
    send_data assignment.get_detailed_csv_report,
              :disposition => 'attachment',
              :type => 'application/vnd.ms-excel',
              :filename => "#{assignment.short_identifier} detailed report.csv"
  end

  # See Assignment.get_svn_export_commands for details
  def download_svn_export_commands
    assignment = Assignment.find(params[:assignment_id])
    svn_commands = assignment.get_svn_export_commands
    send_data svn_commands.join("\n"),
              :disposition => 'attachment',
              :type => 'text/plain',
              :filename => "#{assignment.short_identifier}_svn_exports"
  end

  # See Assignment.get_svn_repo_list for details
  def download_svn_repo_list
    assignment = Assignment.find(params[:assignment_id])
    send_data assignment.get_svn_repo_list,
              :disposition => 'attachment',
              :type => 'text/plain',
              :filename => "#{assignment.short_identifier}_svn_repo_list"
  end

  # This action is called periodically from file_manager.
  def server_time
    render :partial => 'server_time'
  end

  private

  # Used in update_files and file_manager actions
  def set_filebrowser_vars(user_group, assignment)
    user_group.access_repo do |repo|
      @revision = repo.get_latest_revision
      @files = @revision.files_at_path(File.join(@assignment.repository_folder, @path))
      @missing_assignment_files = []
      assignment.assignment_files.each do |assignment_file|
        unless @revision.path_exists?(File.join(assignment.repository_folder,
                                             assignment_file.filename))
          @missing_assignment_files.push(assignment_file)
        end
      end
    end
  end
end
