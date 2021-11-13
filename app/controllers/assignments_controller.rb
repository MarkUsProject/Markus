class AssignmentsController < ApplicationController
  include RepositoryHelper
  include RoutingHelper
  include CriteriaHelper
  include AnnotationCategoriesHelper
  responders :flash
  before_action { authorize! }

  content_security_policy only: [:edit, :new] do |p|
    # required because jquery-ui-timepicker-addon inserts style
    # dynamically. TODO: remove this when possible
    p.style_src :self, "'unsafe-inline'"
  end

  CONFIG_DIRS = {
    peer_review: 'peer-review-config-files',
    starter_files: 'starter-file-config-files'
  }.freeze

  CONFIG_FILES = {
    properties: 'properties.yml',
    tags: 'tags.yml',
    criteria: 'criteria.yml',
    annotations: 'annotations.yml',
    starter_files: File.join(CONFIG_DIRS[:starter_files], 'starter-file-rules.yml'),
    peer_review_properties: File.join(CONFIG_DIRS[:peer_review], 'properties.yml'),
    peer_review_tags: File.join(CONFIG_DIRS[:peer_review], 'tags.yml'),
    peer_review_criteria: File.join(CONFIG_DIRS[:peer_review], 'criteria.yml'),
    peer_review_annotations: File.join(CONFIG_DIRS[:peer_review], 'annotations.yml')
  }.freeze

  # Publicly accessible actions ---------------------------------------

  def show
    assignment = Assignment.find(params[:id])
    @assignment = assignment.is_peer_review? ? assignment.parent_assignment : assignment
    if @assignment.is_hidden
      render 'shared/http_status',
             formats: [:html],
             locals: {
               code: '404',
               message: HttpStatusHelper::ERROR_CODE['message']['404']
             },
             status: 404,
             layout: false
      return
    end

    @grouping = current_user.accepted_grouping_for(@assignment.id)

    if @grouping.nil?
      if @assignment.scanned_exam
        flash_now(:notice, t('assignments.scanned_exam.under_review'))
      elsif @assignment.group_max == 1 && (!@assignment.is_timed ||
                                           Time.current > assignment.section_due_date(@current_user&.section))
        begin
          current_user.create_group_for_working_alone_student(@assignment.id)
        rescue StandardError => e
          flash_message(:error, e.message)
          redirect_to controller: :assignments
          return
        end
        @grouping = @current_user.accepted_grouping_for(@assignment.id)
      end
    end
    unless @grouping.nil?
      flash_message(:warning, I18n.t('assignments.starter_file.changed_warning')) if @grouping.starter_file_changed
      if @assignment.is_timed && !@grouping.start_time.nil? && !@grouping.past_collection_date?
        flash_message(:note, I18n.t('assignments.timed.started_message_html'))
        unless @assignment.starter_file_updated_at.nil?
          flash_message(:note, I18n.t('assignments.timed.starter_file_prompt'))
        end
      elsif @assignment.is_timed && @grouping.start_time.nil? && @grouping.past_collection_date?
        flash_message(:warning, I18n.t('assignments.timed.past_end_time'))
      end
      set_repo_vars(@assignment, @grouping)
    end
    render layout: 'assignment_content'
  end

  def peer_review
    assignment = Assignment.find(params[:id])
    @assignment = assignment.is_peer_review? ? assignment : assignment.pr_assignment
    if @assignment.nil? || @assignment.is_hidden
      render 'shared/http_status',
             formats: [:html],
             locals: {
                 code: '404',
                 message: HttpStatusHelper::ERROR_CODE['message']['404']
             },
             status: 404,
             layout: false
      return
    end

    @student = current_user
    @grouping = current_user.accepted_grouping_for(@assignment.id)
    @prs = current_user.grouping_for(@assignment.parent_assignment.id)&.
        peer_reviews&.where(results: { released_to_students: true })
    if @prs.nil?
      @prs = []
    end

    if @assignment.past_all_collection_dates?
      flash_now(:notice, t('submissions.grading_can_begin'))
    else
      if @assignment.section_due_dates_type
        section_due_dates = Hash.new
        now = Time.current
        Section.all.each do |section|
          collection_time = @assignment.submission_rule.calculate_collection_time(section)
          collection_time = now if now >= collection_time
          if section_due_dates[collection_time].nil?
            section_due_dates[collection_time] = Array.new
          end
          section_due_dates[collection_time].push(section.name)
        end
        section_due_dates.each do |collection_time, sections|
          sections = sections.join(', ')
          if collection_time == now
            flash_now(:notice, t('submissions.grading_can_begin_for_sections',
                                 sections: sections))
          else
            flash_now(:notice, t('submissions.grading_can_begin_after_for_sections',
                                 time: l(collection_time),
                                 sections: sections))
          end
        end
      else
        collection_time = @assignment.submission_rule.calculate_collection_time
        flash_now(:notice, t('submissions.grading_can_begin_after',
                             time: l(collection_time)))
      end
    end
  end

  # Displays "Manage Assignments" page for creating and editing assignment information.
  # Acts as dashboard for students and TAs.
  def index
    if current_user.student?
      @a_id_results = {}
      accepted_groupings = current_user.accepted_groupings.includes(:assignment, { current_submission_used: :results })
      accepted_groupings.each do |grouping|
        if !grouping.assignment.is_hidden && grouping.has_submission?
          submission = grouping.current_submission_used
          if submission.has_remark? && submission.remark_result.released_to_students
            @a_id_results[grouping.assignment.id] = submission.remark_result
          elsif submission.has_result? && submission.get_original_result.released_to_students
            @a_id_results[grouping.assignment.id] = submission.get_original_result
          end
        end
      end

      @g_id_entries = {}
      current_user.grade_entry_students.where(released_to_student: true).includes(:grade_entry_form).each do |g|
        unless g.grade_entry_form.is_hidden
          @g_id_entries[g.assessment_id] = g
        end
      end

      render :student_assignment_list, layout: 'assignment_content'
    else
      render :index, layout: 'assignment_content'
    end
  end

  # Called on editing assignments (GET)
  def edit
    @assignment = Assignment.find_by_id(params[:id])
    past_date = @assignment.section_names_past_due_date
    @assignments = Assignment.all
    @sections = Section.all

    unless @assignment.scanned_exam
      if @assignment.past_collection_date?
        flash_now(:notice, t('assignments.due_date.final_due_date_passed'))
      elsif !past_date.blank?
        flash_now(:notice, t('assignments.due_date.past_due_date_notice') + past_date.join(', '))
      end
    end

    # build section_due_dates for each section that doesn't already have a due date
    Section.all.each do |s|
      unless SectionDueDate.find_by(assessment_id: @assignment.id, section_id: s.id)
        @assignment.section_due_dates.build(section: s)
      end
    end
    @section_due_dates = @assignment.section_due_dates
                                    .sort_by { |s| [SectionDueDate.due_date_for(s.section, @assignment), s.section.name] }
    render :edit, layout: 'assignment_content'
  end

  # Called when editing assignments form is submitted (PUT).
  def update
    @assignment = Assignment.find_by_id(params[:id])
    @assignments = Assignment.all
    @sections = Section.all

    begin
      new_required_files = false
      @assignment.transaction do
        @assignment, new_required_files = process_assignment_form(@assignment)
        @assignment.save!
      end
      if new_required_files && Settings.repository.type == 'git'
        # update list of required files in all repos only if there is a hook that will use that list
        @current_job = UpdateRepoRequiredFilesJob.perform_later(@assignment.id, current_user.user_name)
        session[:job_id] = @current_job.job_id
      end
    rescue
    end
    respond_with @assignment, location: -> { edit_assignment_path(@assignment) }
  end

  # Called in order to generate a form for creating a new assignment.
  # i.e. GET request on assignments/new
  def new
    @assignments = Assignment.all
    @assignment = Assignment.new
    if params[:scanned].present?
      @assignment.scanned_exam = true
    end
    if params[:timed].present?
      @assignment.is_timed = true
    end
    @clone_assignments = Assignment.joins(:assignment_properties)
                                   .where(assignment_properties: { vcs_submit: true })
                                   .order(:id)
    @sections = Section.all

    # build section_due_dates for each section
    Section.all.each { |s| @assignment.section_due_dates.build(section: s)}
    @section_due_dates = @assignment.section_due_dates
                                    .sort_by { |s| s.section.name }
    render :new, layout: 'assignment_content'
  end

  # Called after a new assignment form is submitted.
  def create
    @assignment = Assignment.new
    @assignment.transaction do
      begin
        @assignment, new_required_files = process_assignment_form(@assignment)
        @assignment.token_start_date = @assignment.due_date
        @assignment.token_period = 1
      rescue Exception, RuntimeError => e
        @assignment.errors.add(:base, e.message)
        new_required_files = false
      end
      unless @assignment.save
        @assignments = Assignment.all
        @sections = Section.all
        @clone_assignments = Assignment.joins(:assignment_properties)
                                       .where(assignment_properties: { vcs_submit: true })
                                       .order(:id)
        respond_with @assignment, location: -> { new_assignment_path(@assignment) }
        return
      end
      if params[:persist_groups_assignment]
        clone_warnings = @assignment.clone_groupings_from(params[:persist_groups_assignment])
        unless clone_warnings.empty?
          clone_warnings.each { |w| flash_message(:warning, w) }
        end
      end
      if new_required_files && Settings.repository.type == 'git'
        # update list of required files in all repos only if there is a hook that will use that list
        @current_job = UpdateRepoRequiredFilesJob.perform_later(@assignment.id, current_user.user_name)
        session[:job_id] = @current_job.job_id
      end
    end
    respond_with @assignment, location: -> { edit_assignment_path(@assignment) }
  end

  def summary
    @assignment = Assignment.find(params[:id])
    respond_to do |format|
      format.html { render layout: 'assignment_content' }
      format.json { render json: @assignment.summary_json(@current_user) }
      format.csv do
        data = @assignment.summary_csv(@current_user)
        filename = "#{@assignment.short_identifier}_summary.csv"
        send_data data,
                  disposition: 'attachment',
                  type: 'text/csv',
                  filename: filename
      end
    end
  end

  def stop_test
    test_id = params[:test_run_id].to_i
    assignment_id = params[:id]
    @current_job = AutotestCancelJob.perform_later(assignment_id, [test_id])
    session[:job_id] = @current_job.job_id
    redirect_back(fallback_location: root_path)
  end

  def stop_batch_tests
    test_runs = TestRun.where(test_batch_id: params[:test_batch_id]).pluck(:id)
    assignment_id = params[:id]
    @current_job = AutotestCancelJob.perform_later(assignment_id, test_runs)
    session[:job_id] = @current_job.job_id
    redirect_back(fallback_location: root_path)
  end

  def batch_runs
    @assignment = Assignment.find(params[:id])

    respond_to do |format|
      format.html
      format.json do
        user_ids = current_user.admin? ? Admin.pluck(:id) : current_user.id
        test_runs = TestRun.left_outer_joins(:test_batch, grouping: [:group, :current_result])
                           .where(test_runs: {user_id: user_ids},
                                  'groupings.assessment_id': @assignment.id)
                           .pluck_to_hash(:id,
                                          :test_batch_id,
                                          :grouping_id,
                                          :submission_id,
                                          'test_batches.created_at',
                                          'test_runs.created_at',
                                          'test_runs.status',
                                          'groups.group_name',
                                          'results.id')
        test_runs.each do |test_run|
          created_at_raw = test_run.delete('test_batches.created_at') || test_run.delete('test_runs.created_at')
          test_run['created_at'] = I18n.l(created_at_raw)
          test_run['status'] = test_run['test_runs.status']
          test_run['group_name'] = test_run.delete('groups.group_name')
          test_run['result_id'] = test_run.delete('results.id')
        end
        render json: test_runs
      end
    end
  end

  # Return assignment grade distributions
  def grade_distribution
    assignment = Assignment.find(params[:id])
    summary = {
      name: assignment.short_identifier + ': ' + assignment.description,
      average: assignment.results_average || 0,
      median: assignment.results_median || 0,
      num_submissions_collected: assignment.current_submissions_used.size,
      num_submissions_graded: assignment.current_submissions_used.size -
        assignment.ungraded_submission_results.size,
      num_fails: assignment.results_fails,
      num_zeros: assignment.results_zeros,
      groupings_size: assignment.groupings.size,
      num_outstanding_remark_requests: assignment.outstanding_remark_request_count
    }
    intervals = 20
    assignment_labels = (0..intervals - 1).map { |i| "#{5 * i}-#{5 * i + 5}" }
    assignment_datasets = [
      {
        data: assignment.grade_distribution_array
      }
    ]
    assignment_data = { labels: assignment_labels, datasets: assignment_datasets }
    ta_labels = (0..intervals - 1).map { |i| "#{5 * i}-#{5 * i + 5}" }
    ta_datasets = assignment.tas.map do |ta|
      num_marked_label = t('submissions.how_many_marked',
                           num_marked: assignment.get_num_marked(ta.id),
                           num_assigned: assignment.get_num_assigned(ta.id))
      { label: "#{ta.first_name} #{ta.last_name} (#{num_marked_label})",
        data: ta.grade_distribution_array(assignment, intervals) }
    end
    render json: {
      summary: summary,
      assignment_data: assignment_data,
      ta_data: { labels: ta_labels, datasets: ta_datasets }
    }
  end

  def view_summary
    @assignment = Assignment.find(params[:id])
  end

  def download
    format = params[:format]
    case format
    when 'csv'
      output = Assignment.get_assignment_list(format)
      send_data(output,
                filename: 'assignments.csv',
                type: 'text/csv',
                disposition: 'attachment')
    when 'yml'
      output = Assignment.get_assignment_list(format)
      send_data(output,
                filename: 'assignments.yml',
                type: 'text/yml',
                disposition: 'attachment')
    else
      flash[:error] = t('download_errors.unrecognized_format', format: format)
      redirect_to action: 'index', id: params[:id]
    end
  end

  def upload
    begin
      data = process_file_upload
    rescue Psych::SyntaxError => e
      flash_message(:error, t('upload_errors.syntax_error', error: e.to_s))
    rescue StandardError => e
      flash_message(:error, e.message)
    else
      if data[:type] == '.csv'
        result = Assignment.upload_assignment_list('csv', data[:file].read)
        flash_message(:error, result[:invalid_lines]) unless result[:invalid_lines].empty?
        flash_message(:success, result[:valid_lines]) unless result[:valid_lines].empty?
      elsif data[:type] == '.yml'
        result = Assignment.upload_assignment_list('yml', data[:contents])
        if result.is_a?(StandardError)
          flash_message(:error, result.message)
        end
      end
    end
    redirect_to action: 'index'
  end

  def starter_file
    @assignment = Assignment.find_by_id(params[:id])
    if @assignment.nil?
      render 'shared/http_status',
             locals: { code: '404', message: HttpStatusHelper::ERROR_CODE['message']['404'] },
             status: 404
    else
      render layout: 'assignment_content'
    end
  end

  def populate_starter_file_manager
    assignment = Assignment.find(params[:id])
    if assignment.groupings.exists?
      flash_message(:warning,
                    I18n.t('assignments.starter_file.groupings_exist_warning_html'))
    end
    file_data = []
    assignment.starter_file_groups.order(:id).each do |g|
      file_data << { id: g.id,
                     name: g.name,
                     entry_rename: g.entry_rename,
                     use_rename: g.use_rename,
                     files: starter_file_group_file_data(g) }
    end
    section_data = Section.left_outer_joins(:starter_file_groups)
                          .order(:id)
                          .pluck_to_hash('sections.id as section_id',
                                         'sections.name as section_name',
                                         'starter_file_groups.id as group_id',
                                         'starter_file_groups.name as group_name')
    data = { files: file_data,
             sections: section_data,
             available_after_due: assignment.starter_files_after_due,
             starterfileType: assignment.starter_file_type,
             defaultStarterFileGroup: assignment.default_starter_file_group&.id || '' }
    render json: data
  end

  def update_starter_file
    assignment = Assignment.find(params[:id])
    all_changed = false
    success = true
    ApplicationRecord.transaction do
      assignment.assignment_properties.update!(starter_file_assignment_params)
      all_changed = assignment.assignment_properties.saved_changes?
      params[:sections].each do |section_params|
        Section.find_by(id: section_params[:section_id])
               &.update_starter_file_group(assignment.id, section_params[:group_id])
      end
      starter_file_group_params.each do |group_params|
        starter_file_group = assignment.starter_file_groups.find_by(id: group_params[:id])
        starter_file_group.update!(group_params)
        all_changed ||= starter_file_group.saved_changes? || assignment.assignment_properties.saved_changes?
      end
      assignment.assignment_properties.update!(starter_file_updated_at: Time.current)
    rescue ActiveRecord::RecordInvalid => e
      flash_message(:error, e.message)
      success = false
      raise ActiveRecord::Rollback
    rescue StandardError => e
      flash_message(:error, e.message)
      success = false
      raise ActiveRecord::Rollback
    end
    if success
      flash_message(:success, I18n.t('flash.actions.update.success',
                                     resource_name: I18n.t('assignments.starter_file.title')))
    end
    # mark all groupings with starter files that were changed as changed
    assignment.groupings.update_all(starter_file_changed: true) if success && all_changed
  end

  def download_starter_file_mappings
    assignment = Assignment.find(params[:id])
    mappings = assignment.starter_file_mappings
    file_out = MarkusCsv.generate(mappings, [mappings.first&.keys].compact, &:values)
    send_data(file_out,
              type: 'text/csv',
              filename: "#{assignment.short_identifier}_starter_file_mappings.csv",
              disposition: 'inline')
  end

  # Switch to the assignment with id +params[:id]+. Try to redirect to the same page
  # as the referer url for the new assignment if possible. Otherwise redirect to a
  # default action depending on the type of user:
  #   - edit for admins
  #   - summary for TAs
  #   - show for students
  def switch
    options = referer_options
    if switch_to_same(options)
      redirect_to options
    elsif current_user.admin?
      redirect_to edit_assignment_path(params[:id])
    elsif current_user.ta?
      redirect_to summary_assignment_path(params[:id])
    else # current_user.student?
      redirect_to assignment_path(params[:id])
    end
  end

  def set_boolean_graders_options
    assignment = Assignment.find(params[:id])
    attributes = graders_options_params
    return head 400 if attributes.empty? || attributes[:assignment_properties_attributes].empty?

    unless assignment.update(attributes)
      flash_now(:error, assignment.errors.full_messages.join(' '))
      head 422
      return
    end
    head :ok
  end

  # Start timed assignment for the current user's grouping for this assignment
  def start_timed_assignment
    assignment = Assignment.find(params[:id])
    grouping = current_user.accepted_grouping_for(assignment.id)
    if grouping.nil? && assignment.group_max == 1
      begin
        current_user.create_group_for_working_alone_student(assignment.id)
        grouping = current_user.accepted_grouping_for(assignment.id)
        set_repo_vars(assignment, grouping)
      rescue StandardError => e
        flash_message(:error, e.message)
      end
    end
    return head 400 if grouping.nil?
    authorize! grouping
    unless grouping.update(start_time: Time.current)
      flash_message(:error, grouping.errors.full_messages.join(' '))
    end
    redirect_to action: :show
  end

  # Download a zip file containing an example of starter files that might be assigned to a grouping
  def download_sample_starter_files
    assignment = Assignment.find(params[:id])

    zip_name = "#{assignment.short_identifier}-sample-starter-files.zip"
    zip_path = File.join('tmp', zip_name)

    FileUtils.rm_f(zip_path)

    Zip::File.open(zip_path, create: true) do |zip_file|
      assignment.sample_starter_file_entries.each { |entry| entry.add_files_to_zip_file(zip_file) }
    end
    send_file zip_path, filename: zip_name
  end

  # Downloads a zip file containing all the information and settings about an assignment
  def download_config_files
    assignment = Assignment.find(params[:id])
    child_assignment = Assignment.find_by(parent_assessment_id: params[:id])

    zip_name = "#{assignment.short_identifier}-config-files.zip"
    zip_path = File.join('tmp', zip_name)

    FileUtils.rm_f(zip_path)

    Zip::File.open(zip_path, create: true) do |zipfile|
      zipfile.get_output_stream(CONFIG_FILES[:properties]) do |f|
        f.write(assignment.assignment_properties_config.to_yaml)
      end
      zipfile.get_output_stream(CONFIG_FILES[:tags]) do |f|
        f.write(assignment.tags.pluck_to_hash(:name, :description).to_yaml)
      end
      zipfile.get_output_stream(CONFIG_FILES[:criteria]) do |f|
        yml_criteria = assignment.criteria.reduce({}) { |a, b| a.merge b.to_yml }
        f.write yml_criteria.to_yaml
      end
      zipfile.get_output_stream(CONFIG_FILES[:annotations]) do |f|
        f.write annotation_categories_to_yml(assignment.annotation_categories)
      end
      assignment.starter_file_config_to_zip(zipfile, CONFIG_DIRS[:starter_files], CONFIG_FILES[:starter_files])
      unless child_assignment.nil?
        zipfile.get_output_stream(CONFIG_FILES[:peer_review_properties]) do |f|
          f.write(child_assignment.assignment_properties_config.to_yaml)
        end
        zipfile.get_output_stream(CONFIG_FILES[:peer_review_tags]) do |f|
          f.write(child_assignment.tags.pluck_to_hash(:name, :description).to_yaml)
        end
        zipfile.get_output_stream(CONFIG_FILES[:peer_review_criteria]) do |f|
          yml_criteria = child_assignment.criteria.reduce({}) { |a, b| a.merge b.to_yml }
          f.write yml_criteria.to_yaml
        end
        zipfile.get_output_stream(CONFIG_FILES[:peer_review_annotations]) do |f|
          f.write convert_to_yml(child_assignment.annotation_categories)
        end
        child_assignment.starter_file_config_to_zip(zipfile, CONFIG_DIRS[:starter_files], CONFIG_FILES[:starter_files])
      end
    end
    send_file zip_path, filename: zip_name, type: 'application/zip', disposition: 'attachment'
  end
  # Uploads a zip file containing all the files specified in download_config_files
  # and modifies the assignment settings according to those files.
  def upload_config_files
    upload_file = params.require(:upload_files_for_config)
    raise I18n.t('upload_errors.blank') if upload_file.size == 0
    raise I18n.t('upload_errors.invalid_file_type', type: 'zip') unless File.extname(upload_file.path).casecmp?('.zip')

    Zip::File.open(upload_file.path) do |zipfile|
      ApplicationRecord.transaction do
        # Build assignment from properties
        prop_file = zipfile.get_entry(CONFIG_FILES[:properties])
        assignment = build_uploaded_assignment(prop_file)
        zipfile.remove(prop_file)
        tag_prop = build_hash_from_zip(zipfile, :tags)
        criteria_prop = build_hash_from_zip(zipfile, :criteria)
        annotations_prop = build_hash_from_zip(zipfile, :annotations)
        # Build peer review assignment if it exists
        child_prop_file = zipfile.find_entry(CONFIG_FILES[:peer_review_properties])
        unless child_prop_file.nil?
          child_assignment = build_uploaded_assignment(child_prop_file, assignment)
          child_assignment.save!
          zipfile.remove(child_prop_file)
          child_tag_prop = build_hash_from_zip(zipfile, :peer_review_tags)
          Tag.from_yml(child_tag_prop, child_assignment.id)
          child_criteria_prop = build_hash_from_zip(zipfile, :peer_review_criteria)
          config_criteria(child_assignment, child_criteria_prop)
          child_annotations_prop = build_hash_from_zip(zipfile, :peer_review_annotations)
          upload_annotations_from_yaml(child_annotations_prop, child_assignment)
          config_starter_files(child_assignment, zipfile)
          child_assignment.save!
        end
        assignment.save!
        Tag.from_yml(tag_prop, assignment.id)
        config_criteria(assignment, criteria_prop)
        upload_annotations_from_yaml(annotations_prop, assignment)
        config_starter_files(assignment, zipfile)
        assignment.save!
        redirect_to edit_assignment_path(assignment.id)
      end
    end
  rescue StandardError => e
    flash_message(:error, e.message)
    if params[:is_scanned] == 'true'
      redirect_to new_assignment_path(scanned: true)
    elsif params[:is_timed] == 'true'
      redirect_to new_assignment_path(timed: true)
    else
      redirect_to new_assignment_path
    end
  end

  private

  # Configures the starter files for an +assignment+ provided in the +zip_file+
  def config_starter_files(assignment, zip_file)
    starter_file_settings = build_hash_from_zip(zip_file, :starter_files)
    assignment.starter_file_type = starter_file_settings[:starter_file_type]
    assignment.starter_files_after_due = starter_file_settings[:allow_starter_files_after_due]
    starter_group_mappings = {}
    starter_file_settings[:group_information].each do |group|
      file_group = StarterFileGroup.create!(name: group[:name],
                                            use_rename: group[:use_rename],
                                            entry_rename: group[:entry_rename],
                                            assignment: assignment)
      FileUtils.rm_rf(file_group.path)
      FileUtils.mkdir_p(file_group.path)
      starter_group_mappings[group[:directory_name]] = file_group
    end
    default_name = starter_file_settings[:default_starter_group]
    if !default_name.nil? && starter_group_mappings.key?(default_name)
      assignment.default_starter_file_group_id = starter_group_mappings[default_name].id
    end
    if assignment.is_peer_review?
      zip_starter_path = File.join(CONFIG_DIRS[:peer_review], CONFIG_DIRS[:starter_files], '')
    else
      zip_starter_path = File.join(CONFIG_DIRS[:starter_files], '')
    end
    zip_file.each do |entry|
      if entry.name.match?(/^#{zip_starter_path}/)
        # Set working directory to the location of all the starter file content, then find
        # directory for a starter group and add the file found in that directory to group
        starter_base_dir = entry.name[zip_starter_path.length..-1]
        path_list = starter_base_dir.split(File::SEPARATOR)
        starter_file_group = starter_group_mappings[path_list[0]]
        starter_file_dir_path = File.join(starter_file_group.path, path_list[1..-2])
        starter_file_name = path_list[-1]
        if entry.directory?
          FileUtils.mkdir_p(File.join(starter_file_dir_path, starter_file_name))
        else
          FileUtils.mkdir_p(starter_file_dir_path)
          starter_file_content = entry.get_input_stream.read
          File.write(File.join(starter_file_dir_path, starter_file_name), starter_file_content, mode: 'wb')
        end
      end
    end
    assignment.starter_file_groups.find_each(&:update_entries)
  end

  # Build the tag/criteria/starter file settings file specified by +hash_to_build+ found in +zip_file+
  # Delete the file from the +zip_file+ after loading in the content.
  def build_hash_from_zip(zip_file, hash_to_build)
    yaml_file = zip_file.get_entry(CONFIG_FILES[hash_to_build])
    yaml_content = yaml_file.get_input_stream.read.encode(Encoding::UTF_8, 'UTF-8')
    zip_file.remove(yaml_file)
    properties = parse_yaml_content(yaml_content)
    if [:tags, :peer_review_tags].include?(hash_to_build)
      properties.each { |row| row[:user] = @current_user.user_name }
    end
    properties
  end

  # Ensure that the +assignment+ type (scanned, timed, neither) matches the params
  # If it does not match, raise an error
  def check_assignment_type_match!(assignment)
    timed = params[:is_timed] == 'true'
    scanned = params[:is_scanned] == 'true'
    unless assignment.is_timed == timed && assignment.scanned_exam == scanned
      if assignment.is_timed
        upload_type = I18n.t("activerecord.models.timed_assignment.one")
      elsif assignment.scanned_exam
        upload_type = I18n.t("activerecord.models.scanned_assignment.one")
      else
        upload_type = Assignment.model_name.human
      end
      if timed
        form_type = I18n.t("activerecord.models.timed_assignment.one")
      elsif scanned
        form_type = I18n.t("activerecord.models.scanned_assignment.one")
      else
        form_type = Assignment.model_name.human
      end
      raise I18n.t('assignments.wrong_assignment_type', form_type: form_type, upload_type: upload_type)
    end
  end

  # Builds an uploaded assignment/peer review assignment from it's properties file
  # Precondition: If +parent_assignment+ is not null, this is a peer review assignment.
  #               If building a peer review assignment, prop_file must not be null.
  def build_uploaded_assignment(prop_file, parent_assignment = nil)
    yaml_content = prop_file.get_input_stream.read.encode(Encoding::UTF_8, 'UTF-8')
    properties = parse_yaml_content(yaml_content)
    if parent_assignment.nil?
      assignment = Assignment.new(properties)
      check_assignment_type_match!(assignment)
      assignment.repository_folder = assignment.short_identifier
    else
      # Filter properties not supported by peer review assignments, then build assignment
      peer_review_properties = properties.except(:submission_rule_attributes, :assignment_files_attributes)
      assignment = Assignment.new(peer_review_properties)
      parent_assignment.has_peer_review = true
      assignment.has_peer_review = false
      assignment.parent_assignment = parent_assignment
      assignment.repository_folder = parent_assignment.repository_folder
    end
    assignment
  end

  def set_repo_vars(assignment, grouping)
    grouping.access_repo do |repo|
      @revision = repo.get_revision_by_timestamp(Time.current, assignment.repository_folder)
      @last_modified_date = @revision&.server_timestamp
      files = @revision.tree_at_path(assignment.repository_folder, with_attrs: false)
                       .select do |_, obj|
                         obj.is_a?(Repository::RevisionFile) &&
                           !Repository.get_class.internal_file_names.include?(obj.name)
                       end
      @num_submitted_files = files.length
      missing_assignment_files = grouping.missing_assignment_files(@revision)
      @num_missing_assignment_files = missing_assignment_files.length
    end
  end

  def process_assignment_form(assignment)
    num_files_before = assignment.assignment_files.length
    short_identifier = assignment_params[:short_identifier]
    # remove potentially invalid periods before updating
    unless assignment_params[:assignment_properties_attributes][:scanned_exam] == 'true'
      period_attrs = submission_rule_params['submission_rule_attributes']['periods_attributes']
      periods = period_attrs.to_h.values.map { |h| h[:id].blank? ? nil : h[:id] }
      assignment.submission_rule.periods.where.not(id: periods).each(&:destroy)
    end
    assignment.assign_attributes(assignment_params)
    SubmissionRule.where(assignment: assignment).where.not(id: assignment.submission_rule.id).each(&:destroy)
    process_timed_duration(assignment) if assignment.is_timed
    assignment.repository_folder = short_identifier unless assignment.is_peer_review?
    assignment.save!
    new_required_files = assignment.saved_change_to_only_required_files? ||
                         assignment.saved_change_to_is_hidden? ||
                         assignment.assignment_files.any?(&:saved_changes?) ||
                         num_files_before != assignment.assignment_files.length
    # if there are no section due dates, destroy the objects that were created
    if ['0', nil].include? params[:assignment][:assignment_properties_attributes][:section_due_dates_type]
      assignment.section_due_dates.each(&:destroy)
      assignment.section_due_dates_type = false
      assignment.section_groups_only = false
    else
      assignment.section_due_dates_type = true
      assignment.section_groups_only = true
    end

    if params[:is_group_assignment] == 'true'
      # Is the instructor forming groups?
      if assignment_params[:assignment_properties_attributes][:student_form_groups] == '0'
        assignment.invalid_override = true
      else
        assignment.student_form_groups = true
        assignment.invalid_override = false
        assignment.group_name_autogenerated = true
      end
    else
      assignment.student_form_groups = false
      assignment.invalid_override = false
      assignment.group_min = 1
      assignment.group_max = 1
    end

    return assignment, new_required_files
  end

  # Convert the hours and minutes value given in the params to a duration value
  # and assign it to the duration attribute of +assignment+.
  def process_timed_duration(assignment)
    durs = duration_params['assignment_properties_attributes']['duration']
    assignment.duration = durs['hours'].to_i.hours + durs['minutes'].to_i.minutes
  end

  def starter_file_group_file_data(starter_file_group)
    starter_file_group.files_and_dirs.map do |file|
      if (starter_file_group.path + file).directory?
        { key: "#{file}/" }
      else
        submitted_date = l(File.mtime(starter_file_group.path + file).in_time_zone(current_user.time_zone))
        { key: file, size: 1, submitted_date: submitted_date,
          url: download_file_assignment_starter_file_group_url(starter_file_group.assignment.id,
                                                               starter_file_group.id,
                                                               file_name: file) }
      end
    end
  end

  def graders_options_params
    params.require(:attribute)
          .permit(assignment_properties_attributes: [
                    :assign_graders_to_criteria,
                    :anonymize_groups,
                    :hide_unassigned_criteria
                  ])
  end

  def assignment_params
    params.require(:assignment).permit(
      :short_identifier,
      :description,
      :message,
      :due_date,
      :is_hidden,
      assignment_properties_attributes: [
        :id,
        :allow_web_submits,
        :vcs_submit,
        :display_median_to_students,
        :display_grader_names_to_students,
        :group_min,
        :group_max,
        :student_form_groups,
        :group_name_autogenerated,
        :allow_remarks,
        :remark_due_date,
        :remark_message,
        :section_groups_only,
        :enable_test,
        :enable_student_tests,
        :has_peer_review,
        :assign_graders_to_criteria,
        :group_name_displayed,
        :invalid_override,
        :section_groups_only,
        :only_required_files,
        :section_due_dates_type,
        :scanned_exam,
        :is_timed,
        :start_time
      ],
      section_due_dates_attributes: [
        :_destroy,
        :id,
        :section_id,
        :due_date,
        :start_time
      ],
      assignment_files_attributes:  [
        :_destroy,
        :id,
        :filename
      ],
      submission_rule_attributes: [
        :_destroy,
        :id,
        :type,
        { periods_attributes: [
          :id,
          :deduction,
          :interval,
          :hours,
          :_destroy
        ] }
      ]
    )
  end

  def duration_params
    params.require(:assignment).permit(
      assignment_properties_attributes: [
        duration: [
          :hours,
          :minutes
        ]
      ]
    )
  end

  def submission_rule_params
    params.require(:assignment)
          .permit(submission_rule_attributes: [
            :_destroy,
            :id,
            :type,
            { periods_attributes: [
              :id,
              :deduction,
              :interval,
              :hours,
              :_destroy
            ] }
          ])
  end

  def starter_file_assignment_params
    params.require(:assignment).permit(:starter_file_type, :default_starter_file_group_id, :starter_files_after_due)
  end

  def starter_file_group_params
    params.permit(starter_file_groups: [:id, :name, :entry_rename, :use_rename])
          .require(:starter_file_groups)
  end

  def flash_interpolation_options
    { resource_name: @assignment.short_identifier.blank? ? @assignment.model_name.human : @assignment.short_identifier,
      errors: @assignment.errors.full_messages.join('; ') }
  end

  def switch_to_same(options)
    return false if options[:controller] == 'submissions' && options[:action] == 'file_manager'
    return false if %w[submissions results].include?(options[:controller]) && !options[:id].nil?

    if options[:controller] == 'assignments'
      options[:id] = params[:id]
    elsif options[:assignment_id]
      options[:assignment_id] = params[:id]
    else
      return false
    end
    true
  end
end
