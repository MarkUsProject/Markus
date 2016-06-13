class PeerReviewsController < ApplicationController
  include GroupsHelper

  before_action :set_peer_review, only: [:show, :edit, :update, :destroy]
  before_filter :authorize_only_for_admin

  def index
    @assignment = Assignment.find(params[:assignment_id])
    @section_column = ''
    if Section.all.size > 0
      @section_column = "{
        id: 'section',
        content: '" + t(:'summaries_index.section') + "',
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

  # Returns a dict of: reviewee_id => [list of reviewers].
  def create_map_reviewee_to_reviewers(reviewer_groups, reviewee_groups)
    reviewer_ids = reviewer_groups.map { |reviewer| reviewer['id'] }
    peer_review_map = Hash.new { |hash, key| hash[key] = [] }
    reviewee_groups.each { |reviewee| peer_review_map[reviewee['id']] }

    peer_reviews = PeerReview.where(reviewer_id: reviewer_ids)
    peer_reviews.each do |peer_review|
      reviewee_group_id = peer_review.result.submission.grouping.id
      peer_review_map[reviewee_group_id].push(peer_review.reviewer.id)
    end

    peer_review_map
  end

  # Returns a map of group id => names.
  def create_map_group_id_to_name(reviewer_groups, reviewee_groups)
    # We need to get every possible group so we have a big map of everyone that
    # is present in both tables. This means ids from both the reviewers and the
    # reviewees group, since this data is eligible for use in both tables.
    unique_group_ids = {}
    reviewer_groups.each { |reviewer| unique_group_ids[reviewer['id']] = 0 }
    reviewee_groups.each { |reviewee| unique_group_ids[reviewee['id']] = 0 }

    # Compress into a single list so we can pass it off as a query.
    id_to_group_name_list = []
    unique_group_ids.each do |key, val|
      id_to_group_name_list.push(key)
    end

    # Retrieve all the groups with the unique id list, and map the id => name.
    id_to_group_name_map = {}
    groupings = Grouping.where(id: id_to_group_name_list)
    groupings.each do |grouping|
      id_to_group_name_map[grouping.id] = grouping.group.group_name
    end

    return id_to_group_name_map
  end

  # Returns a map of reviewer_id => num_of_reviews
  def create_map_number_of_reviews_for_reviewer(reviewer_groups)
    number_of_reviews_for_reviewer = {}
    reviewer_groups.each do |reviewer|
      count = PeerReview.where(reviewer_id: reviewer['id']).count
      number_of_reviews_for_reviewer[reviewer['id']] = count
    end
    number_of_reviews_for_reviewer
  end

  def assign_groups
    @assignment = Assignment.find(params[:assignment_id])
    selected_reviewer_group_ids = params[:selectedReviewerGroupIds]
    selected_reviewee_group_ids = params[:selectedRevieweeGroupIds]
    reviewers_to_remove_from_reviewees_map = params[:selectedReviewerInRevieweeGroups]
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
        unassign(reviewers_to_remove_from_reviewees_map)
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
          PeerReview.create(reviewer: reviewer_group, result: result)
        end
      end
    end
  end

  def unassign(reviewers_to_remove_from_reviewees_map)
    reviewers_to_remove_from_reviewees_map.each do |reviewee_id, reviewer_id_to_bool|
      reviewer_id_to_bool.each do |reviewer_id, dummy_value|
        reviewee_group = Grouping.find_by_id(reviewee_id)
        result_id = reviewee_group.current_submission_used.get_latest_result.id
        pr = PeerReview.find_by(result_id: result_id, reviewer_id: reviewer_id)
        pr.destroy
      end
    end
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
