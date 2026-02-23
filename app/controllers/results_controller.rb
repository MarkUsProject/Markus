class ResultsController < ApplicationController
  before_action { authorize! }

  authorize :view_token, through: :view_token_param
  authorize :criterion_id, through: :criterion_id_param

  content_security_policy only: [:edit, :view_marks] do |p|
    # required because heic2any uses libheif which calls
    # eval (javascript) and creates an image as a blob.
    # TODO: remove this when possible
    p.script_src :self, "'strict-dynamic'", "'unsafe-eval'"
    p.img_src :self, :blob
    # required because MathJax dynamically changes
    # style. # TODO: remove this when possible
    p.style_src :self, "'unsafe-inline'"
    p.frame_src(*SubmissionsController::PERMITTED_IFRAME_SRC)
  end

  def show
    respond_to do |format|
      format.json do
        result = record
        submission = result.submission
        assignment = submission.assignment
        course = assignment.course
        remark_submitted = submission.remark_submitted?
        original_result = remark_submitted ? submission.get_original_result : nil
        is_review = result.is_a_review?
        is_reviewer = current_role.student? && current_role.is_reviewer_for?(assignment.pr_assignment, result)
        pr_assignment = is_review ? assignment.pr_assignment : nil

        grouping = submission.grouping

        data = {
          grouping_id: is_reviewer ? nil : submission.grouping_id,
          marking_state: result.marking_state,
          released_to_students: result.released_to_students,
          detailed_annotations: current_role.instructor? || current_role.ta? || is_reviewer,
          revision_identifier: submission.revision_identifier,
          instructor_run: true,
          allow_remarks: is_review ? pr_assignment.allow_remarks : assignment.allow_remarks,
          remark_submitted: remark_submitted,
          remark_request_text: submission.remark_request,
          remark_request_timestamp: submission.remark_request_timestamp,
          assignment_remark_message: assignment.remark_message,
          remark_due_date: is_review ? pr_assignment.remark_due_date : assignment.remark_due_date,
          past_remark_due_date: is_review ? pr_assignment.past_remark_due_date? : assignment.past_remark_due_date?,
          is_reviewer: is_reviewer,
          parent_assignment_id: pr_assignment&.id,
          student_view: current_role.student? && !is_reviewer,
          due_date: I18n.l(grouping.due_date.in_time_zone),
          submission_time: submission.revision_timestamp && I18n.l(submission.revision_timestamp.in_time_zone)
        }
        if original_result.nil?
          data[:overall_comment] = result.overall_comment
          data[:remark_overall_comment] = nil
        else
          data[:overall_comment] = original_result.overall_comment
          data[:remark_overall_comment] = result.overall_comment
        end
        if is_review
          data[:feedback_files] = []
        else
          data[:feedback_files] = submission.feedback_files.where(test_group_result_id: nil).map do |f|
            { id: f.id, filename: f.filename, type: FileHelper.get_file_type(f.filename) }
          end
        end

        if assignment.enable_test
          authorized = allowed_to?(:run_tests?, current_role, context: { assignment: assignment,
                                                                         grouping: grouping,
                                                                         submission: submission })
          data[:enable_test] = true
          data[:can_run_tests] = authorized
        else
          data[:enable_test] = false
          data[:can_run_tests] = false
        end

        data[:can_release] = allowed_to?(:manage_assessments?, current_role)

        # Submission files
        file_data = submission.submission_files.order(:path, :filename).pluck_to_hash(:id, :filename, :path) do |hash|
          hash[:type] = FileHelper.get_file_type(hash[:filename])
          hash
        end
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
          annotation.get_data(include_creator: current_role.instructor? || current_role.ta? || is_reviewer)
        end

        # Annotation categories
        if current_role.instructor? || current_role.ta? || is_reviewer
          annotation_categories = AnnotationCategory.visible_categories(is_review ? pr_assignment : assignment,
                                                                        current_role)
                                                    .includes(:annotation_texts)
          data[:annotation_categories] = annotation_categories.map do |category|
            name_extension = category.flexible_criterion_id.nil? ? '' : " [#{category.flexible_criterion.name}]"
            {
              id: category.id,
              annotation_category_name: category.annotation_category_name + name_extension,
              texts: category.annotation_texts.map do |text|
                {
                  id: text.id,
                  content: text.content || '',
                  deduction: text.deduction
                }
              end,
              flexible_criterion_id: category.flexible_criterion_id
            }
          end
        end

        if current_role.instructor? || current_role.ta?
          data[:sections] = course.sections.pluck(:name)
          data[:notes_count] = submission.grouping.notes.count
          if current_role.ta?
            data[:num_marked] = assignment.get_num_marked(current_role.id, bulk: true)
          else
            data[:num_marked] = assignment.get_num_marked(nil)
          end
          data[:num_collected] = assignment.get_num_collected(current_role.instructor? ? nil : current_role.id)
          if current_role.ta? && assignment.anonymize_groups
            data[:group_name] = "#{Group.model_name.human} #{submission.grouping.id}"
            data[:members] = []
          else
            data[:group_name] = submission.grouping.group.group_name
            data[:members] = submission.grouping.accepted_students.map(&:user_name)
          end
        elsif is_reviewer
          reviewer_group = current_role.grouping_for(assignment.pr_assignment.id)
          data[:num_marked] = PeerReview.get_num_marked(reviewer_group)
          data[:num_collected] = PeerReview.get_num_collected(reviewer_group)
          data[:group_name] = "#{PeerReview.model_name.human} #{result.peer_reviews.ids.first}"
          data[:members] = []
        end

        if current_role.instructor?
          data[:tas] = assignment.ta_memberships.joins(:user).distinct.pluck('users.user_name', 'users.display_name')
        end

        # Marks
        fields = [:id, :name, :description, :position, :max_mark]
        criteria_query = { assessment_id: is_review ? assignment.pr_assignment.id : assignment.id }
        if is_review
          criteria_query[:peer_visible] = true
        else
          criteria_query[:ta_visible] = true
        end
        # Pre-fetch all rubric levels in one query to avoid N+1
        rubric_criteria_ids = RubricCriterion.where(**criteria_query).pluck(:id)
        all_levels = Level.where(criterion_id: rubric_criteria_ids)
                          .order(:mark)
                          .group_by(&:criterion_id)

        marks_map = [CheckboxCriterion, FlexibleCriterion, RubricCriterion].flat_map do |klass|
          criteria = klass.where(**criteria_query)
          criteria_info = criteria.pluck_to_hash(*fields)
          marks_info = criteria.joins(:marks)
                               .where('marks.result_id': result.id)
                               .pluck_to_hash(*fields,
                                              'marks.mark AS mark',
                                              'marks.override AS override',
                                              'criteria.bonus AS bonus')
                               .group_by { |h| h[:id] }
          # adds a criterion type to each of the marks info hashes
          criteria_info.map do |cr|
            info = marks_info[cr[:id]]&.first || cr.merge(mark: nil)

            # Use pre-fetched levels instead of querying per criterion
            if klass == RubricCriterion
              info[:levels] = (all_levels[cr[:id]] || []).map do |l|
                { name: l.name, description: l.description, mark: l.mark }
              end
            end
            info.merge(criterion_type: klass.name)
          end
        end
        marks_map.sort_by! { |a| a[:position] }

        if original_result.nil?
          old_marks = {}
        else
          old_marks = original_result.mark_hash
        end

        if assignment.assign_graders_to_criteria && current_role.ta?
          assigned_criteria = current_role.criterion_ta_associations
                                          .where(assessment_id: assignment.id)
                                          .pluck(:criterion_id)
          if assignment.hide_unassigned_criteria
            marks_map = marks_map.select { |m| assigned_criteria.include? m[:id] }
            old_marks = old_marks.select { |m| assigned_criteria.include? m }
          else
            marks_map = marks_map.partition { |m| assigned_criteria.include? m[:id] }
                                 .flatten
          end
        else
          assigned_criteria = nil
        end

        data[:assigned_criteria] = assigned_criteria
        data[:marks] = marks_map

        data[:old_marks] = old_marks

        # Extra marks
        data[:extra_marks] = result.extra_marks
                                   .pluck_to_hash(:id, :description, :extra_mark, :unit)

        # Grace token deductions
        if is_reviewer || (current_role.ta? && assignment.anonymize_groups)
          data[:grace_token_deductions] = []
        elsif current_role.student?
          data[:grace_token_deductions] =
            submission.grouping
                      .grace_period_deductions
                      .joins(membership: [role: :user])
                      .where('users.user_name': current_user.user_name)
                      .pluck_to_hash(:id, :deduction, 'users.user_name', 'users.display_name')
        else
          data[:grace_token_deductions] =
            submission.grouping
                      .grace_period_deductions
                      .joins(membership: [role: :user])
                      .pluck_to_hash(:id, :deduction, 'users.user_name', 'users.display_name')
        end

        # Totals
        if result.is_a_review?
          data[:assignment_max_mark] = assignment.pr_assignment.max_mark(:peer_visible)
        else
          data[:assignment_max_mark] = assignment.max_mark
        end
        data[:total] = marks_map.pluck('mark')
        data[:old_total] = old_marks.values_at(:mark).compact.sum

        # Tags
        all_tags = assignment.tags.pluck_to_hash(:id, :name)
        data[:current_tags] = submission.grouping.tags.pluck_to_hash(:id, :name)
        data[:available_tags] = all_tags - data[:current_tags]

        render json: data
      end
    end
  end

  def edit
    @host = Rails.application.config.relative_url_root
    @result = record
    @submission = @result.submission
    @grouping = @submission.grouping
    @assignment = @grouping.assignment

    # authorization
    allowed = allowance_to(:run_tests?, current_role, context: { assignment: @assignment,
                                                                 grouping: @grouping,
                                                                 submission: @submission })
    flash_allowance(:notice, allowed) if @assignment.enable_test
    @authorized = allowed.value

    m_logger = MarkusLogger.instance
    m_logger.log("User '#{current_role.user_name}' viewed submission (id: #{@submission.id})" \
                 "of assignment '#{@assignment.short_identifier}' for group '" \
                 "#{@grouping.group.group_name}'")

    # Check whether this group made a submission after the final deadline.
    if @grouping.submitted_after_collection_date? && !@assignment.scanned_exam
      flash_message(:warning,
                    t('results.late_submission_warning_html',
                      url: repo_browser_course_assignment_submissions_path(@current_course, @assignment,
                                                                           grouping_id: @grouping.id)))
    end

    # Check whether marks have been released.
    if @result.released_to_students
      flash_message(:notice, t('results.marks_released'))
    end

    render layout: 'result_content'
  end

  def run_tests
    submission = record.submission

    assignment = Grouping.find(submission.grouping_id).assignment
    # If no test groups can be run by instructors, flash appropriate message and return early
    test_group_categories = assignment.test_groups.pluck(:autotest_settings).pluck('category')
    instructor_runnable = test_group_categories.any? { |category| category.include? 'instructor' }
    unless instructor_runnable
      flash_now(:info, I18n.t('automated_tests.no_instructor_runnable_tests'))
      return
    end

    flash_message(:notice, I18n.t('automated_tests.autotest_run_job.status.in_progress'))
    AutotestRunJob.perform_later(request.protocol + request.host_with_port,
                                 current_role.id,
                                 submission.assignment.id,
                                 [submission.grouping.group_id],
                                 user: current_user)
  end

  ##  Tag Methods  ##
  def add_tag
    # TODO: this should be in the grouping or tag controller
    result = record
    tag = Tag.find(params[:tag_id])
    result.submission.grouping.tags << tag
    head :ok
  end

  def remove_tag
    # TODO: this should be in the grouping or tag controller
    result = record
    tag = Tag.find(params[:tag_id])
    result.submission.grouping.tags.destroy(tag)
    head :ok
  end

  def next_grouping
    filter_data = params[:filterData]
    result = record
    grouping = result.submission.grouping
    assignment = grouping.assignment

    if result.is_a_review? && current_role.is_reviewer_for?(assignment.pr_assignment, result)
      assigned_prs = current_role.grouping_for(assignment.pr_assignment.id).peer_reviews_to_others
      peer_review_ids = result.peer_reviews.order(id: :asc).ids
      if params[:direction] == '1'
        next_grouping = assigned_prs.where('peer_reviews.id > ?', peer_review_ids.last).first
      else
        next_grouping = assigned_prs.where(peer_reviews: { id: ...peer_review_ids.first }).last
      end
      next_result = Result.find_by(id: next_grouping&.result_id)
    else
      reversed = params[:direction] != '1'
      next_grouping = grouping.get_next_grouping(current_role, reversed, filter_data)
      next_result = next_grouping&.current_result
    end

    render json: { next_result: next_result, next_grouping: next_grouping }
  end

  def random_incomplete_submission
    result = record
    grouping = result.submission.grouping

    next_grouping = grouping.get_random_incomplete(current_role)
    next_result = next_grouping&.current_result

    render json: { result_id: next_result&.id, submission_id: next_result&.submission_id,
                   grouping_id: next_grouping&.id }
  end

  def set_released_to_students
    @result = record
    released_to_students = !@result.released_to_students
    @result.released_to_students = released_to_students
    if @result.save
      m_logger = MarkusLogger.instance
      assignment = @result.submission.assignment
      if released_to_students
        m_logger.log("Marks released for assignment '#{assignment.short_identifier}', ID: '" \
                     "#{assignment.id}' (for 1 group).")
      else
        m_logger.log("Marks unreleased for assignment '#{assignment.short_identifier}', ID: '" \
                     "#{assignment.id}' (for 1 group).")
      end
    end
    head :ok
  end

  # Toggles the marking state
  def toggle_marking_state
    @result = record
    @old_marking_state = @result.marking_state

    if @result.marking_state == Result::MARKING_STATES[:complete]
      @result.marking_state = Result::MARKING_STATES[:incomplete]
    else
      @result.marking_state = Result::MARKING_STATES[:complete]
    end

    if @result.save
      head :ok
    else # Failed to pass validations
      # Show error message
      flash_now(:error, @result.errors.full_messages.join(' ;'))
      head :bad_request
    end
  end

  def get_annotations
    result = record
    assignment = record.grouping.assignment
    all_annots = result.annotations.includes(:submission_file, :creator,
                                             { annotation_text: :annotation_category })
    is_reviewer = current_role.student? && current_role.is_reviewer_for?(assignment.pr_assignment, result)

    if result.submission.remark_submitted?
      all_annots += result.submission.get_original_result.annotations
    end

    annotation_data = all_annots.map do |annotation|
      annotation.get_data(include_creator: current_role.instructor? || current_role.ta? || is_reviewer)
    end

    render json: annotation_data
  end

  def update_mark
    result = record
    submission = result.submission
    group = submission.grouping.group
    assignment = submission.grouping.assignment
    mark_value = params[:mark].blank? ? nil : params[:mark].to_f

    is_reviewer = current_role.student? && current_role.is_reviewer_for?(assignment.pr_assignment, result)

    # make this operation atomic (more or less) so that concurrent requests won't make duplicate values
    result_mark = Mark.transaction { result.marks.order(:id).find_or_create_by(criterion_id: params[:criterion_id]) }
    unless result_mark.valid?
      # In case the transaction above doesn't do its job, this will clean up any duplicate marks in the database
      marks = result.marks.where(criterion_id: params[:criterion_id])
      marks.where.not(id: result_mark.id).destroy_all if marks.many?
      result_mark.save
    end

    m_logger = MarkusLogger.instance

    if result_mark.update(mark: mark_value, override: !(mark_value.nil? && result_mark.deductive_annotations_absent?))

      m_logger.log("User '#{current_role.user_name}' updated mark for " \
                   "submission (id: #{submission.id}) of " \
                   "assignment #{assignment.short_identifier} for " \
                   "group #{group.group_name}.",
                   MarkusLogger::INFO)

      if is_reviewer
        reviewer_group = current_role.grouping_for(assignment.pr_assignment.id)
        num_marked = PeerReview.get_num_marked(reviewer_group)
      elsif current_role.ta?
        num_marked = assignment.get_num_marked(current_role.id)
      else
        num_marked = assignment.get_num_marked(nil)
      end
      render json: {
        num_marked: num_marked,
        mark: result_mark.reload.mark,
        mark_override: result_mark.override,
        subtotal: result.get_subtotal,
        total: result.get_total_mark
      }
    else
      m_logger.log('Error while trying to update mark of submission. ' \
                   "User: #{current_role.user_name}, " \
                   "Submission id: #{submission.id}, " \
                   "Assignment: #{assignment.short_identifier}, " \
                   "Group: #{group.group_name}.",
                   MarkusLogger::ERROR)
      render json: result_mark.errors.full_messages.join, status: :bad_request
    end
  end

  def revert_to_automatic_deductions
    result = record
    criterion = Criterion.find_by!(id: params[:criterion_id], type: 'FlexibleCriterion')
    result_mark = result.marks.find_or_create_by(criterion: criterion)

    result_mark.update!(override: false)

    if current_role.ta?
      num_marked = result.submission.grouping.assignment.get_num_marked(current_role.id)
    else
      num_marked = result.submission.grouping.assignment.get_num_marked(nil)
    end
    render json: {
      num_marked: num_marked,
      mark: result_mark.reload.mark,
      subtotal: result.get_subtotal,
      total: result.get_total_mark
    }
  end

  # Check whether the token submitted as the view_token param is valid (matches the result and is not expired)
  def view_token_check
    token_is_good = flash_allowance(:error, allowance_to(:view?), flash.now, most_specific: true).value
    token_is_good ? head(:ok) : head(:unauthorized)
  end

  def view_marks
    # set a successful view token in the session so that it doesn't have to be re-entered for every request
    (session['view_token'] ||= {})[record.id] = view_token_param

    @result = record
    @assignment = @result.submission.grouping.assignment
    @assignment = @assignment.is_peer_review? ? @assignment.parent_assignment : @assignment
    is_review = @result.is_a_review? || @result.is_review_for?(current_role, @assignment)

    if current_role.student?
      @grouping = current_role.accepted_grouping_for(@assignment.id)
      if @grouping.nil?
        redirect_to course_assignment_path(current_course, @assignment)
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
      if !@result.is_a_review? && !@submission
        render 'results/student/no_result'
        return
      end
    else
      @submission = @result.submission
      @grouping = @submission.grouping
    end

    # TODO: Review the various code flows, the duplicate checks are a temporary stop-gap
    if @grouping.nil?
      redirect_to course_assignment_path(current_course, @assignment)
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
      if current_role.student?
        @prs = @grouping.peer_reviews.where(results: { released_to_students: true })
      else
        @reviewer = Grouping.find(params[:reviewer_grouping_id])
        @prs = @reviewer.peer_reviews_to_others
      end

      @current_pr = PeerReview.find_by(result_id: @result.id)
      @current_pr_result = @current_pr.result
      @current_group_name = @current_pr_result.submission.grouping.group.group_name
    end

    if !is_review && @submission.remark_submitted?
      remark_result = @submission.remark_result
      # Check if remark request has been submitted but not released yet
      if !remark_result.remark_request_submitted_at.nil? && !remark_result.released_to_students
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

    @host = Rails.application.config.relative_url_root

    m_logger = MarkusLogger.instance
    m_logger.log("Student '#{current_role.user_name}' viewed results for assignment '#{@assignment.short_identifier}'.")
  end

  def add_extra_mark
    @result = record
    @extra_mark = @result.extra_marks.build(extra_mark_params.merge(unit: ExtraMark::POINTS))
    if @extra_mark.save
      head :ok
    else
      head :bad_request
    end
  end

  def remove_extra_mark
    result = record
    extra_mark = result.extra_marks.find(params[:extra_mark_id])

    extra_mark.destroy
    head :ok
  end

  def update_overall_comment
    record.update(overall_comment: params[:result][:overall_comment])
    head :ok
  end

  def delete_grace_period_deduction
    result = record
    grace_deduction = result.submission.grouping.grace_period_deductions.find(params[:deduction_id])
    grace_deduction.destroy
    head :ok
  end

  def get_test_runs_instructors
    submission = record.submission
    render json: submission.grouping.test_runs_instructors(submission)
  end

  def get_test_runs_instructors_released
    submission = record.submission
    render json: submission.grouping.test_runs_instructors_released(submission)
  end

  # Regenerate the view tokens for the results whose ids are given
  def refresh_view_tokens
    updated = requested_results.filter_map { |r| r.regenerate_view_token ? r.id : nil }
    render json: Result.where(id: updated).pluck(:id, :view_token).to_h
  end

  # Update the view token expiry date for the results whose ids are given
  def update_view_token_expiry
    expiry = params[:expiry_datetime]
    updated = requested_results.filter_map { |r| r.update(view_token_expiry: expiry) ? r.id : nil }
    render json: Result.where(id: updated).pluck(:id, :view_token_expiry).to_h
  end

  # Download a csv containing view token and grouping information for the results whose ids are given
  def download_view_tokens
    data = requested_results.left_outer_joins(grouping: [:group, { accepted_student_memberships: [role: :user] }])
                            .order('groups.group_name')
                            .pluck('groups.group_name',
                                   'users.user_name',
                                   'users.first_name',
                                   'users.last_name',
                                   'users.email',
                                   'users.id_number',
                                   'results.view_token',
                                   'results.view_token_expiry',
                                   'results.id')
    header = [[I18n.t('activerecord.models.group.one'),
               I18n.t('activerecord.attributes.user.user_name'),
               I18n.t('activerecord.attributes.user.first_name'),
               I18n.t('activerecord.attributes.user.last_name'),
               I18n.t('activerecord.attributes.user.email'),
               I18n.t('activerecord.attributes.user.id_number'),
               I18n.t('submissions.release_token'),
               I18n.t('submissions.release_token_expires'),
               I18n.t('submissions.release_token_url')]]
    assignment = Assignment.find(params[:assignment_id])
    csv_string = MarkusCsv.generate(data, header) do |row|
      view_token, view_token_expiry, result_id = row.pop(3)
      view_token_expiry ||= I18n.t('submissions.release_token_expires_null')
      url = view_marks_course_result_url(current_course.id, result_id, view_token: view_token)
      [*row, view_token, view_token_expiry, url]
    end
    send_data csv_string,
              disposition: 'attachment',
              filename: "#{assignment.short_identifier}_release_view_tokens.csv"
  end

  def print
    pdf_report = record.generate_print_pdf
    send_data pdf_report.to_pdf,
              filename: record.print_pdf_filename,
              type: 'application/pdf'
  end

  private

  def extra_mark_params
    params.require(:extra_mark).permit(:result,
                                       :description,
                                       :extra_mark)
  end

  def view_token_param
    params[:view_token] || session['view_token']&.[](record&.id&.to_s)
  end

  def criterion_id_param
    params[:criterion_id]
  end

  def requested_results
    Result.joins(grouping: :assignment)
          .where('results.id': params[:result_ids], 'assessments.id': params[:assignment_id])
  end
end
