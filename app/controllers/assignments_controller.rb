class AssignmentsController < ApplicationController
  include RepositoryHelper
  include RoutingHelper
  include CriteriaHelper
  include AnnotationCategoriesHelper
  include AutomatedTestsHelper
  responders :flash
  before_action { authorize! }

  content_security_policy only: [:edit, :new] do |p|
    # required because jquery-ui-timepicker-addon inserts style
    # dynamically. TODO: remove this when possible
    p.style_src :self, "'unsafe-inline'"
  end

  CONFIG_FILES = {
    properties: 'properties.yml',
    tags: 'tags.yml',
    criteria: 'criteria.yml',
    annotations: 'annotations.yml',
    automated_tests_dir_entry: File.join('automated-test-config-files', 'automated-test-files'),
    automated_tests: File.join('automated-test-config-files', 'automated-test-specs.json'),
    starter_files: File.join('starter-file-config-files', 'starter-file-rules.yml'),
    peer_review_properties: File.join('peer-review-config-files', 'properties.yml'),
    peer_review_tags: File.join('peer-review-config-files', 'tags.yml'),
    peer_review_criteria: File.join('peer-review-config-files', 'criteria.yml'),
    peer_review_annotations: File.join('peer-review-config-files', 'annotations.yml'),
    peer_review_starter_files: File.join('peer-review-config-files',
                                         'starter-file-config-files',
                                         'starter-file-rules.yml')
  }.freeze

  # Publicly accessible actions ---------------------------------------

  def show
    assignment = record
    @assignment = assignment.is_peer_review? ? assignment.parent_assignment : assignment
    unless allowed_to?(:see_hidden?)
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

    @grouping = current_role.accepted_grouping_for(@assignment.id)

    if @grouping.nil?
      if @assignment.scanned_exam
        flash_now(:notice, t('assignments.scanned_exam.under_review'))
      elsif @assignment.group_max == 1 && (!@assignment.is_timed ||
                                           Time.current > assignment.section_due_date(current_role&.section))
        begin
          current_role.create_group_for_working_alone_student(@assignment.id)
        rescue StandardError => e
          flash_message(:error, e.message)
          redirect_to controller: :assignments
          return
        end
        @grouping = current_role.accepted_grouping_for(@assignment.id)
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
    assignment = record
    @assignment = assignment.is_peer_review? ? assignment : assignment.pr_assignment
    if @assignment.nil? || !allowed_to?(:see_hidden?)
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

    @student = current_role
    @grouping = current_role.accepted_grouping_for(@assignment.id)
    @prs = current_role.grouping_for(@assignment.parent_assignment.id)&.
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
        current_course.sections.find_each do |section|
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
    if current_role.student?
      @a_id_results = {}
      accepted_groupings = current_role.accepted_groupings.includes(:assignment, current_submission_used: :results)
      accepted_groupings.each do |grouping|
        if allowed_to?(:see_hidden?, grouping.assignment) && grouping.has_submission?
          submission = grouping.current_submission_used
          if submission.has_remark? && submission.remark_result.released_to_students
            @a_id_results[grouping.assignment.id] = submission.remark_result
          elsif submission.has_result? && submission.get_original_result.released_to_students
            @a_id_results[grouping.assignment.id] = submission.get_original_result
          end
        end
      end

      @g_id_entries = {}
      current_role.grade_entry_students.where(released_to_student: true).includes(:grade_entry_form).each do |g|
        if allowed_to?(:see_hidden?, g.grade_entry_form)
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
    @assignment = record
    past_date = @assignment.section_names_past_due_date
    @assignments = current_course.assignments
    @sections = current_course.sections

    unless @assignment.scanned_exam
      if @assignment.past_collection_date?
        flash_now(:notice, t('assignments.due_date.final_due_date_passed'))
      elsif !past_date.blank?
        flash_now(:notice, t('assignments.due_date.past_due_date_notice') + past_date.join(', '))
      end
    end

    # build assessment_section_properties for each section that doesn't already have one
    current_course.sections.find_each do |s|
      unless AssessmentSectionProperties.find_by(assessment_id: @assignment.id, section_id: s.id)
        @assignment.assessment_section_properties.build(section: s)
      end
    end
    @assessment_section_properties = @assignment.assessment_section_properties
    @assessment_section_properties.sort_by do |s|
      [AssessmentSectionProperties.due_date_for(s.section, @assignment), s.section.name]
    end
    render :edit, layout: 'assignment_content'
  end

  # Called when editing assignments form is submitted (PUT).
  def update
    @assignment = record
    @assignments = current_course.assignments
    @sections = current_course.sections
    begin
      @assignment.transaction do
        @assignment = process_assignment_form(@assignment)
        @assignment.save!
      end
    rescue
    end
    respond_with @assignment, location: -> { edit_course_assignment_path(current_course, @assignment) }
  end

  # Called in order to generate a form for creating a new assignment.
  # i.e. GET request on assignments/new
  def new
    @assignments = current_course.assignments
    @assignment = @assignments.new
    if params[:scanned].present?
      @assignment.scanned_exam = true
    end
    if params[:timed].present?
      @assignment.is_timed = true
    end
    @clone_assignments = @assignments.joins(:assignment_properties)
                                     .where(assignment_properties: { vcs_submit: true })
                                     .order(:id)
    @sections = current_course.sections

    # build assessment_section_properties for each section
    @sections.each { |s| @assignment.assessment_section_properties.build(section: s) }
    @assessment_section_properties = @assignment.assessment_section_properties
                                                .sort_by { |s| s.section.name }
    render :new, layout: 'assignment_content'
  end

  # Called after a new assignment form is submitted.
  def create
    @assignment = current_course.assignments.new
    @assignment.transaction do
      begin
        @assignment = process_assignment_form(@assignment)
        @assignment.token_start_date = @assignment.due_date
        @assignment.token_period = 1
      rescue Exception, RuntimeError => e
        @assignment.errors.add(:base, e.message)
      end
      unless @assignment.save
        @assignments = current_course.assignments
        @sections = current_course.sections
        @clone_assignments = @assignments.joins(:assignment_properties)
                                         .where(assignment_properties: { vcs_submit: true })
                                         .order(:id)
        respond_with @assignment, location: -> { new_course_assignment_path(current_course, @assignment) }
        return
      end
      if params[:persist_groups_assignment]
        clone_warnings = @assignment.clone_groupings_from(params[:persist_groups_assignment])
        unless clone_warnings.empty?
          clone_warnings.each { |w| flash_message(:warning, w) }
        end
      end
    end
    respond_with @assignment, location: -> { edit_course_assignment_path(current_course, @assignment) }
  end

  def summary
    @assignment = record
    respond_to do |format|
      format.html { render layout: 'assignment_content' }
      format.json { render json: @assignment.summary_json(current_role) }
      format.csv do
        data = @assignment.summary_csv(current_role)
        filename = "#{@assignment.short_identifier}_summary.csv"
        send_data data,
                  disposition: 'attachment',
                  type: 'text/csv',
                  filename: filename
      end
    end
  end

  def download_test_results
    @assignment = record
    respond_to do |format|
      format.json do
        data = @assignment.summary_test_result_json
        filename = "#{@assignment.short_identifier}_test_results.json"
        send_data data,
                  disposition: 'attachment',
                  type: 'application/json',
                  filename: filename
      end
      format.csv do
        data = @assignment.summary_test_result_csv
        filename = "#{@assignment.short_identifier}_test_results.csv"
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
    @assignment = record

    respond_to do |format|
      format.html
      format.json do
        role_ids = current_role.instructor? ? current_course.instructors.ids : current_role.id
        test_runs = TestRun.left_outer_joins(:test_batch, grouping: [:group, :current_result])
                           .where(test_runs: { role_id: role_ids },
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
    assignment = record
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
    @assignment = record
  end

  def starter_file
    @assignment = record
    if @assignment.nil?
      render 'shared/http_status',
             locals: { code: '404', message: HttpStatusHelper::ERROR_CODE['message']['404'] },
             status: 404
    else
      render layout: 'assignment_content'
    end
  end

  def populate_starter_file_manager
    assignment = record
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
    section_data = current_course.sections
                                 .left_outer_joins(:starter_file_groups)
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
    assignment = record
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
    assignment = record
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
  #   - edit for instructors
  #   - summary for TAs
  #   - show for students
  def switch
    options = referer_options
    if switch_to_same(options)
      redirect_to options
    elsif current_role.instructor?
      redirect_to edit_course_assignment_path(current_course, params[:id])
    elsif current_role.ta?
      redirect_to summary_course_assignment_path(current_course, params[:id])
    else # current_role.student?
      redirect_to course_assignment_path(current_course, params[:id])
    end
  end

  def set_boolean_graders_options
    assignment = record
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
    assignment = record
    grouping = current_role.accepted_grouping_for(assignment.id)
    if grouping.nil? && assignment.group_max == 1
      begin
        current_role.create_group_for_working_alone_student(assignment.id)
        grouping = current_role.accepted_grouping_for(assignment.id)
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
    assignment = record

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
    assignment = record
    child_assignment = Assignment.find_by(parent_assessment_id: params[:id])

    zip_name = "#{assignment.short_identifier}-config-files.zip"
    zip_path = File.join('tmp', zip_name)

    FileUtils.rm_f(zip_path)

    Zip::File.open(zip_path, create: true) do |zipfile|
      zipfile.get_output_stream(CONFIG_FILES[:properties]) do |f|
        f.write(assignment.assignment_properties_config.to_yaml)
      end
      zipfile.get_output_stream(CONFIG_FILES[:criteria]) do |f|
        yml_criteria = assignment.criteria.reduce({}) { |a, b| a.merge b.to_yml }
        f.write yml_criteria.to_yaml
      end
      zipfile.get_output_stream(CONFIG_FILES[:annotations]) do |f|
        f.write annotation_categories_to_yml(assignment.annotation_categories)
      end
      unless assignment.scanned_exam
        assignment.automated_test_config_to_zip(zipfile, CONFIG_FILES[:automated_tests_dir_entry],
                                                CONFIG_FILES[:automated_tests])
      end
      assignment.starter_file_config_to_zip(zipfile, CONFIG_FILES[:starter_files])
      zipfile.get_output_stream(CONFIG_FILES[:tags]) do |f|
        f.write(assignment.tags.pluck_to_hash(:name, :description).to_yaml)
      end
      unless child_assignment.nil?
        zipfile.get_output_stream(CONFIG_FILES[:peer_review_properties]) do |f|
          f.write(child_assignment.assignment_properties_config.to_yaml)
        end
        zipfile.get_output_stream(CONFIG_FILES[:peer_review_criteria]) do |f|
          yml_criteria = child_assignment.criteria.reduce({}) { |a, b| a.merge b.to_yml }
          f.write yml_criteria.to_yaml
        end
        zipfile.get_output_stream(CONFIG_FILES[:peer_review_annotations]) do |f|
          f.write annotation_categories_to_yml(child_assignment.annotation_categories)
        end
        child_assignment.starter_file_config_to_zip(zipfile, CONFIG_FILES[:peer_review_starter_files])
        zipfile.get_output_stream(CONFIG_FILES[:peer_review_tags]) do |f|
          f.write(child_assignment.tags.pluck_to_hash(:name, :description).to_yaml)
        end
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
        tag_prop = build_hash_from_zip(zipfile, :tags)
        criteria_prop = build_hash_from_zip(zipfile, :criteria)
        annotations_prop = build_hash_from_zip(zipfile, :annotations)
        # Build peer review assignment if it exists
        child_prop_file = zipfile.find_entry(CONFIG_FILES[:peer_review_properties])
        unless child_prop_file.nil?
          child_assignment = build_uploaded_assignment(child_prop_file, assignment)
          child_assignment.save!
          child_tag_prop = build_hash_from_zip(zipfile, :peer_review_tags)
          Tag.from_yml(child_tag_prop, current_course, child_assignment.id, true)
          child_criteria_prop = build_hash_from_zip(zipfile, :peer_review_criteria)
          upload_criteria_from_yaml(child_assignment, child_criteria_prop)
          child_annotations_prop = build_hash_from_zip(zipfile, :peer_review_annotations)
          upload_annotations_from_yaml(child_annotations_prop, child_assignment)
          config_starter_files(child_assignment, zipfile)
          child_assignment.save!
        end
        assignment.save!
        Tag.from_yml(tag_prop, current_course, assignment.id, true)
        upload_criteria_from_yaml(assignment, criteria_prop)
        upload_annotations_from_yaml(annotations_prop, assignment)
        config_automated_tests(assignment, zipfile) unless assignment.scanned_exam
        config_starter_files(assignment, zipfile)
        assignment.save!
        redirect_to edit_course_assignment_path(current_course, assignment)
      end
    end
  rescue StandardError => e
    flash_message(:error, e.message)
    redirect_to course_assignments_path(current_course)
  end

  private

  # Configures the automated test files and settings for an +assignment+ provided in the +zip_file+
  def config_automated_tests(assignment, zip_file)
    spec_file = zip_file.get_entry(CONFIG_FILES[:automated_tests])
    spec_content = spec_file.get_input_stream.read.encode(Encoding::UTF_8, 'UTF-8')
    begin
      spec_data = JSON.parse(spec_content)
    rescue JSON::ParserError
      raise I18n.t('automated_tests.invalid_specs_file')
    else
      update_test_groups_from_specs(assignment, spec_data) unless spec_data.empty?
      test_file_glob_pattern = File.join(CONFIG_FILES[:automated_tests_dir_entry], '**', '*')
      zip_file.glob(test_file_glob_pattern) do |entry|
        zip_file_path = Pathname.new(entry.name)
        filename = zip_file_path.relative_path_from(CONFIG_FILES[:automated_tests_dir_entry])
        file_path = File.join(assignment.autotest_files_dir, filename.to_s)
        if entry.directory?
          FileUtils.mkdir_p(file_path)
        else
          FileUtils.mkdir_p(File.dirname(file_path))
          test_file_content = entry.get_input_stream.read
          File.write(file_path, test_file_content, mode: 'wb')
        end
      end
    end
  end

  # Configures the starter files for an +assignment+ provided in the +zip_file+
  def config_starter_files(assignment, zip_file)
    starter_config_file = assignment.is_peer_review? ? :peer_review_starter_files : :starter_files
    starter_file_settings = build_hash_from_zip(zip_file, starter_config_file).symbolize_keys
    starter_group_mappings = {}
    starter_file_settings[:starter_file_groups].each do |group|
      group = group.symbolize_keys
      file_group = StarterFileGroup.create!(name: group[:name],
                                            use_rename: group[:use_rename],
                                            entry_rename: group[:entry_rename],
                                            assignment: assignment)
      starter_group_mappings[group[:directory_name]] = file_group
    end
    default_name = starter_file_settings[:default_starter_file_group]
    if !default_name.nil? && starter_group_mappings.key?(default_name)
      assignment.default_starter_file_group_id = starter_group_mappings[default_name].id
    end
    zip_starter_dir = File.dirname(CONFIG_FILES[starter_config_file])
    starter_file_glob_pattern = File.join(zip_starter_dir, '**', '*')
    zip_file.glob(starter_file_glob_pattern) do |entry|
      next if entry.name == CONFIG_FILES[starter_config_file]
      # Set working directory to the location of all the starter file content, then find
      # directory for a starter group and add the file found in that directory to group
      zip_file_path = Pathname.new(entry.name)
      starter_base_dir = zip_file_path.relative_path_from(zip_starter_dir)
      grouping_dir = starter_base_dir.descend.first.to_s
      starter_file_group = starter_group_mappings[grouping_dir]
      sub_dir, filename = starter_base_dir.relative_path_from(grouping_dir).split
      starter_file_dir_path = File.join(starter_file_group.path, sub_dir.to_s)
      starter_file_name = filename.to_s
      if entry.directory?
        FileUtils.mkdir_p(File.join(starter_file_dir_path, starter_file_name))
      else
        FileUtils.mkdir_p(starter_file_dir_path)
        starter_file_content = entry.get_input_stream.read
        File.write(File.join(starter_file_dir_path, starter_file_name), starter_file_content, mode: 'wb')
      end
    end
    assignment.starter_file_groups.find_each(&:update_entries)
  end

  # Build the tag/criteria/starter file settings file specified by +hash_to_build+ found in +zip_file+
  # Delete the file from the +zip_file+ after loading in the content.
  def build_hash_from_zip(zip_file, hash_to_build)
    yaml_file = zip_file.get_entry(CONFIG_FILES[hash_to_build])
    yaml_content = yaml_file.get_input_stream.read.encode(Encoding::UTF_8, 'UTF-8')
    properties = parse_yaml_content(yaml_content)
    if [:tags, :peer_review_tags].include?(hash_to_build)
      properties.each { |row| row[:user] = current_role.user_name }
    end
    properties
  end

  # Builds an uploaded assignment/peer review assignment from its properties file
  # Precondition: prop_file must be a Zip::Entry object
  #               If +parent_assignment+ is not nil, this is a peer review assignment.
  def build_uploaded_assignment(prop_file, parent_assignment = nil)
    yaml_content = prop_file.get_input_stream.read.encode(Encoding::UTF_8, 'UTF-8')
    properties = parse_yaml_content(yaml_content).deep_symbolize_keys
    if parent_assignment.nil?
      assignment = current_course.assignments.new(properties)
      assignment.repository_folder = assignment.short_identifier
    else
      # Filter properties not supported by peer review assignments, then build assignment
      peer_review_properties = properties.except(:submission_rule_attributes, :assignment_files_attributes)
      assignment = current_course.assignments.new(peer_review_properties)
      parent_assignment.has_peer_review = true
      assignment.has_peer_review = false
      assignment.enable_test = false
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

    # if there are no assessment section properties, destroy the objects that were created
    if ['0', nil].include? params[:assignment][:assignment_properties_attributes][:section_due_dates_type]
      assignment.assessment_section_properties.each(&:destroy)
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

    assignment
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
        submitted_date = l(File.mtime(starter_file_group.path + file).in_time_zone(current_role.time_zone))
        { key: file, size: 1, submitted_date: submitted_date,
          url: download_file_course_starter_file_group_url(starter_file_group.assignment.course,
                                                           starter_file_group,
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
      assessment_section_properties_attributes: [
        :_destroy,
        :id,
        :section_id,
        :due_date,
        :start_time,
        :is_hidden
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
    return false if options[:controller] == 'submissions' && %w[file_manager repo_browser].include?(options[:action])
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
