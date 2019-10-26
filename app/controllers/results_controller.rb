class ResultsController < ApplicationController
  include TagsHelper
  before_action :authorize_only_for_admin,
                except: [:show, :edit, :update_mark, :view_marks,
                         :create, :add_extra_mark, :next_grouping,
                         :get_annotations,
                         :update_overall_comment, :remove_extra_mark,
                         :toggle_marking_state,
                         :download, :download_zip,
                         :update_remark_request, :cancel_remark_request,
                         :get_test_runs_instructors, :get_test_runs_instructors_released
                ]
  before_action :authorize_for_ta_and_admin,
                only: [:create, :add_extra_mark,
                       :remove_extra_mark, :get_test_runs_instructors]
  before_action :authorize_for_user,
                only: [:show, :download, :download_zip,
                       :view_marks, :get_annotations, :show]
  before_action :authorize_for_student,
                only: [:update_remark_request,
                       :cancel_remark_request,
                       :get_test_runs_instructors_released]
  before_action only: [:edit, :update_mark, :toggle_marking_state,
                       :update_overall_comment, :next_grouping] do |c|
                  c.authorize_for_ta_admin_and_reviewer(params[:assignment_id], params[:id])
                end
  after_action  :update_remark_request_count,
                only: [:update_remark_request, :cancel_remark_request,
                       :set_released_to_students]

  def show
    respond_to do |format|
      format.json do
        result = Result.find(params[:id])
        submission = result.submission
        assignment = submission.assignment
        remark_submitted = submission.remark_submitted?
        original_result = remark_submitted ? submission.get_original_result : nil
        submission.feedback_files
        is_review = result.is_a_review?
        is_reviewer = current_user.student? && current_user.is_reviewer_for?(assignment.pr_assignment, result)

        if current_user.student? && !@current_user.is_reviewer_for?(assignment.pr_assignment, result)
          grouping = current_user.accepted_grouping_for(assignment.id)
          if submission.grouping_id != grouping&.id ||
              !result.released_to_students?
            head :forbidden
            return
          end
        end

        data = {
          grouping_id: is_reviewer ? nil : submission.grouping_id,
          marking_state: result.marking_state,
          released_to_students: result.released_to_students,
          detailed_annotations:
            @current_user.admin? || @current_user.ta? || is_reviewer,
          revision_identifier: submission.revision_identifier,
          instructor_run: true,
          allow_remarks: assignment.allow_remarks,
          remark_submitted: remark_submitted,
          remark_request_text: submission.remark_request,
          remark_request_timestamp: submission.remark_request_timestamp,
          assignment_remark_message: assignment.remark_message,
          remark_due_date: assignment.remark_due_date,
          past_remark_due_date: assignment.past_remark_due_date?,
          is_reviewer: is_reviewer,
          student_view: @current_user.student? && !is_reviewer
        }
        if original_result.nil?
          data[:overall_comment] = result.overall_comment
          data[:remark_overall_comment] = nil
        else
          data[:overall_comment] = original_result.overall_comment
          data[:remark_overall_comment] = result.overall_comment
        end
        if is_reviewer
          data[:feedback_files] = []
        else
          data[:feedback_files] = submission.feedback_files.map do |f|
            { id: f.id, filename: f.filename }
          end
        end

        if assignment.enable_test
          begin
            authorize! assignment, to: :run_tests? # TODO: Remove it when reasons will have the dependent policy details
            authorize! submission, to: :run_tests?
            authorized = true
          rescue ActionPolicy::Unauthorized
            authorized = false
          end
          data[:enable_test] = true
          data[:can_run_tests] = authorized
        else
          data[:enable_test] = false
          data[:can_run_tests] = false
        end

        # Submission files
        file_data = submission.submission_files.order(:path, :filename).pluck_to_hash(:id, :filename, :path)
        file_data.reject! { |f| Repository.get_class.internal_file_names.include? f[:filename] }
        data[:submission_files] = file_data

        # Annotations
        all_annotations = result.annotations
                                .includes(:submission_file, :creator,
                                          annotation_text: :annotation_category)
        if remark_submitted
          all_annotations += original_result.annotations
                                            .includes(:submission_file, :creator,
                                                      annotation_text: :annotation_category)
        end

        data[:annotations] = all_annotations.map do |annotation|
          annotation.get_data(@current_user.admin? || @current_user.ta?)
        end

        # Annotation categories
        if current_user.admin? || current_user.ta?
          annotation_categories = assignment.annotation_categories
                                            .order(:position)
                                            .includes(:annotation_texts)
          data[:annotation_categories] = annotation_categories.map do |category|
            {
              id: category.id,
              annotation_category_name: category.annotation_category_name,
              texts: category.annotation_texts.map do |text|
                {
                  id: text.id,
                  content: text.content
                }
              end
            }
          end
          data[:notes_count] = submission.grouping.notes.count
          data[:num_marked] = assignment.get_num_marked(current_user.admin? ? nil : current_user.id)
          data[:num_assigned] = assignment.get_num_assigned(current_user.admin? ? nil : current_user.id)
          data[:group_name] = submission.grouping.get_group_name
        elsif is_reviewer
          reviewer_group = current_user.grouping_for(assignment.pr_assignment.id)
          data[:num_marked] = PeerReview.get_num_marked(reviewer_group)
          data[:num_assigned] = PeerReview.get_num_assigned(reviewer_group)
          data[:group_name] = PeerReview.model_name.human
        end

        # Marks
        common_fields = [:id, :name, :position, :max_mark]
        marks_map = [CheckboxCriterion, FlexibleCriterion, RubricCriterion].flat_map do |klass|
          if klass == RubricCriterion
            fields = common_fields + [
              :level_0_name, :level_0_description,
              :level_1_name, :level_1_description,
              :level_2_name, :level_2_description,
              :level_3_name, :level_3_description,
              :level_4_name, :level_4_description
            ]
          else
            fields = common_fields + [:description]
          end
          criteria = klass.where(assignment_id: is_review ? assignment.pr_assignment.id : assignment.id,
                                 ta_visible: !is_review,
                                 peer_visible: is_review)
          criteria_info = criteria.pluck_to_hash(*fields)
          marks_info = criteria.joins(:marks)
                               .where('marks.result_id': result.id)
                               .pluck_to_hash(*fields, 'marks.mark')
                               .group_by { |h| h[:id] }
          criteria_info.map do |h|
            info = marks_info[h[:id]]&.first || h.merge('marks.mark': nil)
            info.merge(criterion_type: klass.name)
          end
        end
        marks_map.sort! { |a, b| a[:position] <=> b[:position] }

        if assignment.assign_graders_to_criteria && current_user.ta?
          assigned_criteria = current_user.criterion_ta_associations
                                          .where(assignment_id: assignment.id)
                                          .pluck(:criterion_type, :criterion_id)
                                          .map { |t, id| "#{t}-#{id}" }

          marks_map = marks_map.partition { |m| assigned_criteria.include? "#{m[:criterion_type]}-#{m[:id]}" }
                               .flatten
        else
          assigned_criteria = nil
        end

        data[:assigned_criteria] = assigned_criteria
        data[:marks] = marks_map

        if original_result.nil?
          old_marks = {}
        else
          old_marks = original_result.mark_hash
        end
        data[:old_marks] = old_marks

        # Extra marks
        data[:extra_marks] = result.extra_marks
                                   .pluck_to_hash(:id, :description, :extra_mark, :unit)

        # Grace token deductions
        if is_reviewer
          data[:grace_token_deductions] = []
        else
          data[:grace_token_deductions] =
            submission.grouping
              .grace_period_deductions
              .joins(membership: :user)
              .pluck_to_hash(:id, :deduction, 'users.user_name', 'users.first_name', 'users.last_name')
        end

        # Totals
        data[:assignment_max_mark] =
          result.is_a_review? ? assignment.pr_assignment.max_mark(:peer) : assignment.max_mark(:ta)
        data[:total] = result.total_mark
        data[:old_total] = original_result&.total_mark

        # Tags
        data[:current_tags] = Tag.left_outer_joins(:groupings)
                                 .where('groupings_tags.grouping_id': submission.grouping_id)
                                 .pluck_to_hash(:id, :name)
        data[:available_tags] = Tag.left_outer_joins(:groupings)
                                   .where.not('groupings_tags.grouping_id': submission.grouping_id)
                                   .or(Tag.left_outer_joins(:groupings).where('groupings.id': nil))
                                   .pluck_to_hash(:id, :name)

        render json: data
      end
    end
  end

  def edit
    @host = Rails.application.config.action_controller.relative_url_root
    @result = Result.find(params[:id])
    @submission = @result.submission
    @grouping = @submission.grouping
    @assignment = @grouping.assignment

    # authorization
    begin
      authorize! @assignment, to: :run_tests? # TODO: Remove it when reasons will have the dependent policy details
      authorize! @submission, to: :run_tests?
      @authorized = true
    rescue ActionPolicy::Unauthorized => e
      @authorized = false
      if @assignment.enable_test
        flash_now(:notice, e.result.reasons.full_messages.join(' '))
      end
    end

    m_logger = MarkusLogger.instance
    m_logger.log("User '#{current_user.user_name}' viewed submission (id: #{@submission.id})" +
                 "of assignment '#{@assignment.short_identifier}' for group '" +
                 "#{@grouping.group.group_name}'")

    # Check whether this group made a submission after the final deadline.
    if @grouping.past_due_date?
      flash_message(:warning,
                    t('results.late_submission_warning_html',
                      url: repo_browser_assignment_submission_path(@assignment, @grouping)))
    end

    # Check whether marks have been released.
    if @result.released_to_students
      flash_message(:notice, t('results.marks_released'))
    end

    render layout: 'result_content'
  end

  def run_tests
    begin
      submission = Result.find(params[:id]).submission
      assignment = submission.assignment
      authorize! assignment, to: :run_tests? # TODO: Remove it when reasons will have the dependent policy details
      authorize! submission, to: :run_tests?
      test_run = submission.create_test_run!(user: current_user)
      AutotestRunJob.perform_later(request.protocol + request.host_with_port, current_user.id, [{ id: test_run.id }])
      flash_message(:notice, I18n.t('automated_tests.tests_running'))
    rescue StandardError => e
      message = e.is_a?(ActionPolicy::Unauthorized) ? e.result.reasons.full_messages.join(' ') : e.message
      flash_message(:error, message)
    end
    redirect_back(fallback_location: root_path)
  end

  def stop_test
    test_id = params[:test_run_id].to_i
    AutotestCancelJob.perform_later(request.protocol + request.host_with_port, [test_id])
    redirect_back(fallback_location: root_path)
  end

  ##  Tag Methods  ##
  def add_tag
    result = Result.find(params[:id])
    create_grouping_tag_association_from_existing_tag(result.submission.grouping_id,
                                                      params[:tag_id])
    head :ok
  end

  def remove_tag
    result = Result.find(params[:id])
    grouping = result.submission.grouping
    delete_grouping_tag_association(params[:tag_id],
                                    grouping)
    head :ok
  end

  def next_grouping
    assignment = Assignment.find(params[:assignment_id])
    result = Result.find(params[:id])
    grouping = result.submission.grouping

    if current_user.ta?
      groupings = current_user.groupings
                              .where(assignment: assignment)
                              .joins(:group)
                              .order('group_name')
      if params[:direction] == '1'
        next_grouping = groupings.where('group_name > ?', grouping.group.group_name).first
      else
        next_grouping = groupings.where('group_name < ?', grouping.group.group_name).last
      end
    elsif result.is_a_review? && current_user.is_reviewer_for?(assignment.pr_assignment, result)
      assigned_prs = current_user.grouping_for(assignment.pr_assignment.id).peer_reviews_to_others
      if params[:direction] == '1'
        next_pr = assigned_prs.where('peer_reviews.id > ?', result.peer_review_id).first
      else
        next_pr = assigned_prs.where('peer_reviews.id < ?', result.peer_review_id).last
      end
      next_result = Result.find(next_pr.result_id)
      redirect_to action: 'edit', id: next_result.id
      return
    else
      groupings = assignment.groupings.joins(:group).order('group_name')
      if params[:direction] == '1'
        next_grouping = groupings.where('group_name > ?', grouping.group.group_name).first
      else
        next_grouping = groupings.where('group_name < ?', grouping.group.group_name).last
      end
    end

    next_result = next_grouping&.current_result
    if next_result.nil?
      redirect_to controller: 'submissions', action: 'browse'
    else
      redirect_to action: 'edit', id: next_result.id
    end
  end

  def set_released_to_students
    @result = Result.find(params[:id])
    released_to_students = !@result.released_to_students
    @result.released_to_students = released_to_students
    if @result.save
      @result.submission.assignment.assignment_stat.refresh_grade_distribution
      @result.submission.assignment.update_results_stats
      m_logger = MarkusLogger.instance
      assignment = @result.submission.assignment
      if released_to_students
        m_logger.log("Marks released for assignment '#{assignment.short_identifier}', ID: '"\
                     "#{assignment.id}' (for 1 group).")
      else
        m_logger.log("Marks unreleased for assignment '#{assignment.short_identifier}', ID: '"\
                     "#{assignment.id}' (for 1 group).")
      end
    end
    head :ok
  end

  # Toggles the marking state
  def toggle_marking_state
    @result = Result.find(params[:id])
    @old_marking_state = @result.marking_state

    if @result.marking_state == Result::MARKING_STATES[:complete]
      @result.marking_state = Result::MARKING_STATES[:incomplete]
    else
      @result.marking_state = Result::MARKING_STATES[:complete]
    end

    if @result.save
      @result.submission.assignment.assignment_stat.refresh_grade_distribution
      @result.submission.assignment.update_results_stats
      head :ok
    else # Failed to pass validations
      # Show error message
      render 'results/marker/show_result_error'
    end
  end

  def download
    if params[:download_zip_button]
      download_zip
      return
    end
    #Ensure student doesn't download a file not submitted by his own grouping

    unless authorized_to_download?(file_id: params[:select_file_id],
                                   assignment_id: params[:assignment_id],
                                   result_id: params[:id],
                                   from_codeviewer: params[:from_codeviewer])
      render 'shared/http_status', formats: [:html],
             locals: { code: '404',
                          message: HttpStatusHelper::ERROR_CODE[
                              'message']['404'] }, status: 404,
             layout: false
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
      flash_message(:error, e.message)
      redirect_to action: 'edit',
                  assignment_id: params[:assignment_id],
                  submission_id: file.submission,
                  id: file.submission.get_latest_result.id
      return
    end
    filename = file.filename
    #Display the file in the page if it is an image/pdf, and download button
    #was not explicitly pressed
    if file.is_supported_image? && !params[:show_in_browser].nil?
      send_data file_contents, type: 'image', disposition: 'inline',
        filename: filename
    else
      send_data file_contents, filename: filename, disposition: 'attachment'
    end
  end

  def download_zip

    #Ensure student doesn't download files not submitted by his own grouping
    unless authorized_to_download?(submission_id: params[:submission_id],
                                   assignment_id: params[:assignment_id],
                                   result_id: params[:id],
                                   from_codeviewer: params[:from_codeviewer])
      render 'shared/http_status', formats: [:html],
             locals: { code: '404',
                          message: HttpStatusHelper::ERROR_CODE[
                              'message']['404'] }, status: 404,
             layout: false
      return
    end

    submission = Submission.find(params[:submission_id])
    if submission.revision_identifier.nil?
      render plain: t('submissions.no_files_available')
      return
    end

    assignment = Assignment.find(params[:assignment_id])
    grouping = Grouping.find(submission.grouping_id)
    revision_identifier = submission.revision_identifier
    repo_folder = assignment.repository_folder
    zip_name = "#{repo_folder}-#{grouping.group.repo_name}"

    zip_path = if params[:include_annotations] == 'true'
                 "tmp/#{assignment.short_identifier}_" +
                     "#{grouping.group.group_name}_r#{revision_identifier}_ann.zip"
               else
                 "tmp/#{assignment.short_identifier}_" +
                     "#{grouping.group.group_name}_r#{revision_identifier}.zip"
               end

    files = submission.submission_files
    Zip::File.open(zip_path, Zip::File::CREATE) do |zip_file|
      grouping.group.access_repo do |repo|
        revision = repo.get_revision(revision_identifier)
        repo.send_tree_to_zip(assignment.repository_folder, zip_file, zip_name, revision) do |file|
          submission_file = files.find_by(filename: file.name, path: file.path)
          submission_file.retrieve_file(params[:include_annotations] == 'true' && !submission_file.is_supported_image?)
        end
      end
    end
    # Send the Zip file
    send_file zip_path, disposition: 'inline',
              filename: zip_name + '.zip'
  end

  def get_annotations
    result = Result.find(params[:id])
    all_annots = result.annotations.includes(:submission_file, :creator,
                                             { annotation_text: :annotation_category })
    if result.submission.remark_submitted?
      all_annots += result.submission.get_original_result.annotations
    end

    annotation_data = all_annots.map do |annotation|
      annotation.get_data(@current_user.admin? || @current_user.ta?)
    end

    render json: annotation_data
  end

  def update_mark
    result = Result.find(params[:id])
    submission = result.submission
    group = submission.grouping.group
    assignment = submission.grouping.assignment
    mark_value = params[:mark].blank? ? nil : params[:mark].to_f

    result_mark = result.marks.find_or_create_by(
      markable_id: params[:markable_id],
      markable_type: params[:markable_type]
    )

    m_logger = MarkusLogger.instance

    if result_mark.update(mark: mark_value)
      m_logger.log("User '#{current_user.user_name}' updated mark for " +
                   "submission (id: #{submission.id}) of " +
                   "assignment #{assignment.short_identifier} for " +
                   "group #{group.group_name}.",
                   MarkusLogger::INFO)
      if assignment.assign_graders_to_criteria && @current_user.ta?
        num_marked = assignment.get_num_marked(@current_user.id)
      else
        num_marked = assignment.get_num_marked(nil)
      end
      render json: {
        num_marked: num_marked
      }
    else
      m_logger.log("Error while trying to update mark of submission. " +
                   "User: #{current_user.user_name}, " +
                   "Submission id: #{submission.id}, " +
                   "Assignment: #{assignment.short_identifier}, " +
                   "Group: #{group.group_name}.",
                   MarkusLogger::ERROR)
      render json: result_mark.errors.full_messages.join, status: :bad_request
    end
  end

  def view_marks
    @assignment = Assignment.find(params[:assignment_id])
    result_from_id = Result.find(params[:id])
    is_review = result_from_id.is_a_review? || result_from_id.is_review_for?(@current_user, @assignment)

    if current_user.student?
      @grouping = current_user.accepted_grouping_for(@assignment.id)
      if @grouping.nil?
        redirect_to controller: 'assignments',
                    action: 'student_interface',
                    id: params[:id]
        return
      end
      unless is_review || @grouping.has_submission?
        render 'results/student/no_submission'
        return
      end
      @submission = @grouping.current_submission_used
      unless is_review || @submission.has_result?
        render 'results/student/no_result'
        return
      end
      if result_from_id.is_a_review?
        @result = result_from_id
      else
        unless @submission
          render 'results/student/no_result'
          return
        end
        @result = @submission.get_original_result
      end
    else
      @result = result_from_id
      @submission = @result.submission
      @grouping = @submission.grouping
    end

    # TODO Review the various code flows, the duplicate checks are a temporary stop-gap
    if @grouping.nil?
      redirect_to controller: 'assignments',
                  action: 'student_interface',
                  id: params[:id]
      return
    end
    unless is_review || @grouping.has_submission?
      render 'results/student/no_submission'
      return
    end
    unless is_review || @submission.has_result?
      render 'results/student/no_result'
      return
    end

    if is_review
      if @current_user.student?
        @prs = @grouping.peer_reviews.where(results: { released_to_students: true })
      else
        @reviewer = Grouping.find(params[:reviewer_grouping_id])
        @prs = @reviewer.peer_reviews_to_others
      end

      @current_pr = PeerReview.find_by(result_id: @result.id)
      @current_pr_result = @current_pr.result
      @current_group_name = @current_pr_result.submission.grouping.group.group_name
    end

    @old_result = nil
    if !is_review && @submission.remark_submitted?
      @old_result = @result
      @result = @submission.remark_result
      # Check if remark request has been submitted but not released yet
      if !@result.remark_request_submitted_at.nil? && !@result.released_to_students
        render 'results/student/no_remark_result'
        return
      end
    end
    unless is_review || @result.released_to_students
      render 'results/student/no_result'
      return
    end

    @annotation_categories = @assignment.annotation_categories
    @group = @grouping.group
    @files = @submission.submission_files.sort do |a, b|
      File.join(a.path, a.filename) <=> File.join(b.path, b.filename)
    end
    @feedback_files = @submission.feedback_files
    @extra_marks_points = @result.extra_marks.points
    @extra_marks_percentage = @result.extra_marks.percentage
    @marks_map = Hash.new
    @old_marks_map = Hash.new

    if @result.is_a_review?
      if @current_user.is_reviewer_for?(@assignment.pr_assignment, @result) ||
          !@grouping.membership_status(current_user).nil? || !@current_user.student?
        @mark_criteria = @assignment.get_criteria(:peer)
      end
    else
      @mark_criteria = @assignment.get_criteria(:ta)
    end

    @mark_criteria.each do |criterion|
      mark = criterion.marks.find_or_create_by(result_id: @result.id)
      mark.save(validate: false)

      # See the 'edit' method documentation for reasoning on why two elements are used.
      @marks_map[[criterion.class.to_s, criterion.id]] = mark

      if @old_result
        oldmark = criterion.marks.find_or_create_by(result_id: @old_result.id)
        oldmark.save(validate: false)

        # See the 'edit' method documentation for reasoning on why two elements are used.
        @old_marks_map[[criterion.class.to_s, criterion.id]] = oldmark
      end
    end

    @host = Rails.application.config.action_controller.relative_url_root

    m_logger = MarkusLogger.instance
    m_logger.log("Student '#{current_user.user_name}' viewed results for assignment " +
                 "'#{@assignment.short_identifier}'.")
  end

  def add_extra_mark
    @result = Result.find(params[:id])
    @extra_mark = @result.extra_marks.build(extra_mark_params.merge(unit: ExtraMark::POINTS))
    if @extra_mark.save
      # need to re-calculate total mark
      @result.update_total_mark
      head :ok
    else
      head :bad_request
    end
  end

  def remove_extra_mark
    extra_mark = ExtraMark.find(params[:id])
    result = extra_mark.result

    extra_mark.destroy
    result.update_total_mark
    head :ok
  end

  def update_overall_comment
    Result.find(params[:id]).update(overall_comment: params[:result][:overall_comment])
    flash_message :success,
                  t('flash.actions.update.success', resource_name: Result.human_attribute_name(:overall_comment))
    head :ok
  end

  def update_remark_request
    @assignment = Assignment.find(params[:assignment_id])
    if @assignment.past_remark_due_date?
      head :bad_request
    else
      @submission = Submission.find(params[:id])
      @submission.update(
        remark_request: params[:submission][:remark_request],
        remark_request_timestamp: Time.zone.now
      )
      if params[:save]
        flash_message(:success, I18n.t('results.remark.update_success'))
        head :ok
      elsif params[:submit]
        unless @submission.remark_result
          @submission.make_remark_result
          @submission.non_pr_results.reload
        end
        @submission.remark_result.update(marking_state: Result::MARKING_STATES[:incomplete])
        @submission.get_original_result.update(released_to_students: false)
        render js: 'location.reload();'
      else
        head :bad_request
      end
    end
  end

  # Allows student to cancel a remark request.
  def cancel_remark_request
    submission = Submission.find(params[:submission_id])

    submission.remark_result.destroy
    submission.get_original_result.update(released_to_students: true)

    redirect_to controller: 'results',
                action: 'view_marks',
                id: params[:id]
  end

  def delete_grace_period_deduction
    result = Result.find(params[:id])
    grace_deduction = result.submission.grouping.grace_period_deductions.find(params[:deduction_id])
    grace_deduction.destroy
    head :ok
  end

  def get_test_runs_instructors
    submission = Submission.find(params[:submission_id])
    test_runs = submission.grouping.test_runs_instructors(submission)
    render json: test_runs.group_by { |t| t['test_runs.id'] }
  end

  def get_test_runs_instructors_released
    submission = Submission.find(params[:submission_id])
    test_runs = submission.grouping.test_runs_instructors_released(submission)
    render json: test_runs.group_by { |t| t['test_runs.id'] }
  end

  private

  #Return true if submission_id or file_id matches between accepted_student and
  #current_user. This is to prevent students from downloading files that they
  #or their group have not submitted. Return false otherwise.
  def authorized_to_download?(map)
    #If the user is a ta or admin, return true as they are authorized.
    if current_user.admin? || current_user.ta?
      return true
    end

    assignment = Assignment.find(map[:assignment_id])
    result = Result.find(map[:result_id])

    if current_user.is_reviewer_for?(assignment.pr_assignment, result) &&
        map[:from_codeviewer] != nil
      return true
    end

    submission = if map[:file_id]
                   sub_file = SubmissionFile.find_by(id: map[:file_id])
                   sub_file.submission unless sub_file.nil?
                 elsif map[:submission_id]
                   Submission.find(map[:submission_id])
                 end
    if submission
      #Check that current_user is in fact in grouping that sub_file belongs to
      !submission.grouping.accepted_students.find { |user|
        user == current_user
      }.nil?
    else
      false
    end
  end

  def update_remark_request_count
    Assignment.find(params[:assignment_id]).update_remark_request_count
  end

  private

  def extra_mark_params
    params.require(:extra_mark).permit(:result,
                                       :description,
                                       :extra_mark)
  end
end
