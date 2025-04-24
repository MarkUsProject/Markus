class PeerReviewsController < ApplicationController
  include RandomAssignHelper

  before_action { authorize! }

  layout 'assignment_content'

  def index
    @assignment = Assignment.find(params[:assignment_id])

    unless @assignment.is_peer_review?
      redirect_to edit_course_assignment_path(current_course, @assignment)
      return
    end

    @section_column = ''
    if current_course.sections.exists?
      @section_column = "{
        id: 'section',
        content: '#{Section.model_name.human}',
        sortable: true
      },"
    end
  end

  def populate
    assignment = Assignment.find(params[:assignment_id])
    peer_reviews = assignment.pr_peer_reviews.except(:order)

    # A map of reviewee_id => [reviewer_ids].
    reviewee_to_reviewers_map = peer_reviews.joins(:reviewee)
                                            .pluck('groupings.id', :reviewer_id)
                                            .group_by { |reviewee_id, _| reviewee_id }
    reviewee_to_reviewers_map.transform_values! { |rows| rows.pluck(1) }

    # A map of grouping_id => group_name (both assignment and parent assignment groupings).
    id_to_group_names_map = assignment.groupings.or(assignment.parent_assignment.groupings)
                                      .joins(:group)
                                      .pluck('groupings.id', 'groups.group_name').to_h

    render json: {
      reviewer_groups: assignment.all_grouping_data,
      reviewee_groups: assignment.parent_assignment.all_grouping_data,
      reviewee_to_reviewers_map: reviewee_to_reviewers_map,
      id_to_group_names_map: id_to_group_names_map,
      num_reviews_map: peer_reviews.group(:reviewer_id).count,
      sections: current_course.sections.pluck(:id, :name).to_h
    }
  end

  def populate_table
    assignment = Assignment.find(params[:assignment_id])
    peer_review_data = assignment.pr_peer_reviews
                                 .joins(reviewer: :group,
                                        result: { grouping: :group })
                                 .pluck_to_hash(
                                   'peer_reviews.id as _id',
                                   'results.id as result_id',
                                   'results.marking_state',
                                   'results.released_to_students',
                                   'groups.group_name as reviewer_name',
                                   'groups_groupings.group_name as reviewee_name'
                                 )

    total_marks = Result.get_total_marks(peer_review_data.pluck('result_id'))
    peer_review_data.each do |data|
      data[:final_grade] = total_marks[data['result_id']]
      data[:marking_state] = data['results.released_to_students'] ? 'released' : data['results.marking_state']
      data[:max_mark] = assignment.peer_criteria.sum(&:max_mark)
    end

    render json: peer_review_data
  end

  # Get data for all reviews for a given reviewer.
  def list_reviews
    assignment = Assignment.find(params[:assignment_id]).pr_assignment
    if current_role.is_a_reviewer?(assignment)
      # grab only the groupings of reviewees that this reviewer
      # is responsible for
      grouping = current_role.grouping_for(assignment.id)
      groupings = grouping.peer_reviews_to_others
                          .joins(:result)
                          .order('peer_reviews.id')
                          .pluck_to_hash('peer_reviews.id', 'results.id', 'results.marking_state as marking_state')
    else
      groupings = []
    end

    render json: groupings
  end

  def show_reviews
    assignment = Assignment.find(params[:assignment_id])
    # grab the first peer review of the reviewee group
    pr = current_role.grouping_for(assignment.id).peer_reviews.first

    if !pr.nil?
      redirect_to show_result_course_peer_review_path(current_course.id, id: pr.id)
    else
      render 'shared/http_status',
             formats: [:html],
             locals: { code: '404', message: HttpStatusHelper::ERROR_CODE['message']['404'] },
             status: :not_found,
             layout: false
    end
  end

  def show_result
    redirect_to view_marks_course_assignment_result_path(current_course, params[:assignment_id], record.result_id)
  end

  def assign_groups
    @assignment = Assignment.find(params[:assignment_id])
    selected_reviewer_group_ids = params[:selectedReviewerGroupIds] || []
    selected_reviewee_group_ids = params[:selectedRevieweeGroupIds] || []
    reviewers_to_remove_from_reviewees_map = params[:selectedReviewerInRevieweeGroups] || {}
    action_string = params[:actionString]
    num_groups_for_reviewers = params[:numGroupsToAssign].to_i

    if %w[assign random_assign].include?(action_string)
      if selected_reviewer_group_ids.empty?
        flash_now(:error, t('peer_reviews.errors.select_a_reviewer'))
        head :bad_request
        return
      elsif selected_reviewee_group_ids.empty?
        flash_now(:error, t('peer_reviews.errors.select_a_reviewee'))
        head :bad_request
        return
      end
    end

    case action_string
    when 'random_assign'
      begin
        perform_random_assignment(@assignment, num_groups_for_reviewers,
                                  selected_reviewer_group_ids, selected_reviewee_group_ids)
      rescue UnableToRandomlyAssignGroupException
        flash_now(:error, t('peer_reviews.errors.random_assign_failure'))
        head :bad_request
        return
      end
    when 'assign'
      reviewer_groups = Grouping.joins(:assignment).where(id: selected_reviewer_group_ids,
                                                          'assessments.course_id': current_course.id)
      reviewee_groups = Grouping.joins(:assignment).where(id: selected_reviewee_group_ids,
                                                          'assessments.course_id': current_course.id)
      begin
        PeerReview.assign(reviewer_groups, reviewee_groups)
      rescue ActiveRecord::RecordInvalid => e
        flash_now(:error, e.message)
        head :bad_request
        return
      rescue SubmissionsNotCollectedException
        flash_now(:error, t('peer_reviews.errors.collect_submissions_first'))
        head :bad_request
        return
      end
    when 'unassign'
      peer_reviews_filtered = PeerReview.joins(:reviewer, :reviewee)
                                        .where(reviewer: { id: selected_reviewer_group_ids },
                                               reviewee: { id: selected_reviewee_group_ids })
                                        .pluck(['reviewer.id', 'reviewee.id'])
      peer_reviews_filtered.each do |reviewer_id, reviewiee_id|
        reviewers_to_remove_from_reviewees_map[reviewiee_id] ||= {} # Initialize if does not exist
        reviewers_to_remove_from_reviewees_map[reviewiee_id][reviewer_id] = true
      end

      deleted_count, undeleted_reviews = PeerReview.unassign(reviewers_to_remove_from_reviewees_map)
      if !undeleted_reviews.empty? && deleted_count == 0
        flash_now(:error, t('peer_reviews.errors.cannot_unassign_any_reviewers'))
        return
      elsif !undeleted_reviews.empty?
        message = t('peer_reviews.errors.cannot_unassign_all_reviewers',
                    deleted_count: deleted_count.to_s, undeleted_reviews: undeleted_reviews.first(5).join(', '))
        if undeleted_reviews.length > 5
          message += " #{t('additional_not_shown', count: undeleted_reviews.length - 5)}"
        end
        flash_now(:error, message)
      elsif deleted_count > 0
        flash_now(:success, t('peer_reviews.unassigned_reviewers_successfully', deleted_count: deleted_count.to_s))
      end
    else
      head :bad_request
      return
    end

    head :ok
  end

  def peer_review_mapping
    assignment = Assignment.find(params[:assignment_id])
    naming_map = PeerReview.get_mappings_for assignment

    file_out = MarkusCsv.generate(naming_map) do |reviewee, reviewers|
      [reviewee] + reviewers
    end

    send_data file_out,
              type: 'text/csv',
              disposition: 'attachment',
              filename: "#{assignment.short_identifier}_peer_review_mapping.csv"
  end

  def upload
    begin
      data = process_file_upload(['.csv'])
    rescue StandardError => e
      flash_message(:error, e.message)
    else
      assignment = Assignment.find(params[:assignment_id])
      result = PeerReview.from_csv(assignment, data[:contents])
      flash_csv_result(result)
    end
    redirect_to action: 'index', assignment_id: params[:assignment_id]
  end

  private

  # Never trust parameters from the scary internet, only allow the white list through.
  def peer_review_params
    params.require(:peer_review).permit(:reviewer_id, :result_id)
  end
end

class SubmissionsNotCollectedException < RuntimeError
end
