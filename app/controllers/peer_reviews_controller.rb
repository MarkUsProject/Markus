class PeerReviewsController < ApplicationController
  include GroupsHelper
  include PeerReviewHelper

  before_action :set_peer_review, only: [:show, :edit, :update, :destroy]
  before_filter :authorize_only_for_admin

  def index
    @assignment = Assignment.find(params[:assignment_id])
    @section_column = ''
    if Section.all.size > 0
      @section_column = "{
        id: 'section',
        content: '#{t('summaries_index.section')}',
        sortable: true
      },"
    end
  end

  def populate
    @assignment = Assignment.find(params[:assignment_id])

    reviewer_groups = get_groupings_table_info()
    reviewee_groups = get_groupings_table_info(@assignment.parent_assignment)

    reviewee_to_reviewers_map = create_map_reviewee_to_reviewers(reviewer_groups, reviewee_groups)
    id_to_group_names_map = create_map_group_id_to_name(reviewer_groups, reviewee_groups)
    num_reviews_map = create_map_number_of_reviews_for_reviewer(reviewer_groups)

    render json: [reviewer_groups, reviewee_groups, reviewee_to_reviewers_map,
                  id_to_group_names_map, num_reviews_map]
  end

  def assign_groups
    @assignment = Assignment.find(params[:assignment_id])
    selected_reviewer_group_ids = params[:selectedReviewerGroupIds] || []
    selected_reviewee_group_ids = params[:selectedRevieweeGroupIds] || []
    reviewers_to_remove_from_reviewees_map = params[:selectedReviewerInRevieweeGroups] || {}
    action_string = params[:actionString]

    if action_string == 'random_assign' or action_string == 'assign'
      if selected_reviewer_group_ids.nil? or selected_reviewer_group_ids.empty?
        render text: t('peer_review.empty_list_reviewers'), status: 400
        return
      elsif selected_reviewee_group_ids.nil? or selected_reviewee_group_ids.empty?
        render text: t('peer_review.empty_list_reviewees'), status: 400
        return
      end
    end

    case action_string
      when 'random_assign'
        randomly_assign
      when 'assign'
        reviewer_groups = Grouping.where(id: selected_reviewer_group_ids)
        reviewee_groups = Grouping.where(id: selected_reviewee_group_ids)
        assign(reviewer_groups, reviewee_groups)
      when 'unassign'
        unassign(selected_reviewee_group_ids, reviewers_to_remove_from_reviewees_map)
      else
        render text: t('peer_review.problem'), status: 400
        return
    end

    head :ok
  end

  def randomly_assign
    # TODO
  end

  def assign(reviewer_groups, reviewee_groups)
    reviewer_groups.each do |reviewer_group|
      reviewee_groups.each do |reviewee_group|
        result = reviewee_group.current_submission_used.get_latest_result
        unless PeerReview.exists?(reviewer: reviewer_group, result: result)
          PeerReview.create!(reviewer: reviewer_group, result: result)
        end
      end
    end
  end

  def unassign(selected_reviewee_group_ids, reviewers_to_remove_from_reviewees_map)
    # First do specific unassigning.
    reviewers_to_remove_from_reviewees_map.each do |reviewee_id, reviewer_id_to_bool|
      reviewer_id_to_bool.each do |reviewer_id, dummy_value|
        reviewee_group = Grouping.find_by_id(reviewee_id)
        result_id = reviewee_group.current_submission_used.get_latest_result.id
        pr = PeerReview.find_by(result_id: result_id, reviewer_id: reviewer_id)
        pr.destroy
      end
    end

    selected_reviewee_group_ids.each { |reviewee_id| Grouping.find(reviewee_id).peer_reviews.map(&:destroy) }
  end

  def download_reviewer_reviewee_mapping
    @assignment = Assignment.find(params[:assignment_id])
    reviewer_groups = get_groupings_table_info()
    reviewer_ids = reviewer_groups.map { |reviewer| reviewer['id'] }
    peer_reviews = PeerReview.where(reviewer_id: reviewer_ids)

    file_out = MarkusCSV.generate(peer_reviews) do |peer_review|
      [peer_review.result.id, peer_review.reviewer.group.group_name]
    end

    send_data(file_out, type: 'text/csv', disposition: 'inline',
              filename: 'peer_review_group_to_group_mapping.csv')
  end

  def csv_upload_handler
    assignment_id = params[:assignment_id]

    if params[:peer_review_mapping].nil?
      flash_message(flash[:error], I18n.t('csv.group_to_grader'))
    else
      result = MarkusCSV.parse(params[:peer_review_mapping].read,
                               encoding: params[:encoding]) do |row|
        raise CSVInvalidLineError if row.empty?
        result = Result.find(row.first)
        reviewer = Grouping.joins(:group).find_by(
                                groups: { group_name: row.second },
                                assignment_id: assignment_id)
        PeerReview.create!(result: result, reviewer: reviewer)
      end
      unless result[:invalid_lines].empty?
        flash_message(:error, result[:invalid_lines])
      end
      unless result[:valid_lines].empty?
        flash_message(:success, result[:valid_lines])
      end
    end

    redirect_to action: 'index', assignment_id: assignment_id
  end

  private
  # Use callbacks to share common setup or constraints between actions.
  def set_peer_review
    @peer_review = PeerReview.find(params[:id])
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def peer_review_params
    params.require(:peer_review).permit(:reviewer_id, :result_id)
  end
end
