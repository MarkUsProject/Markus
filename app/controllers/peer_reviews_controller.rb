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
        content: '" + I18n.t(:'summaries_index.section') + "',
        sortable: true
      },"
    end

    if @assignment.marking_scheme_type == 'rubric'
      @criteria = @assignment.rubric_criteria
    else
      @criteria = @assignment.flexible_criteria
    end
  end

  def populate
    @assignment = Assignment.find(params[:assignment_id])  # Needed for the following functions.
    reviewer_groups = get_groupings_table_info
    reviewee_groups = get_groupings_table_info(@assignment.parent_assignment)
    peer_review_map = populate_peer_reviews(reviewer_groups, reviewee_groups)
    id_to_group_names_map = populate_all_group_names(reviewer_groups, reviewee_groups)
    render json: [reviewer_groups, reviewee_groups, peer_review_map, id_to_group_names_map]
  end

  # Should return a dict of: reviewee_id => [list of reviewers].
  def populate_peer_reviews(reviewer_groups, reviewee_groups)
    reviewer_ids = []
    reviewer_groups.each { |reviewer| reviewer_ids.push(reviewer['id']) }

    peer_review_map = {}
    reviewee_groups.each { |reviewee| peer_review_map[reviewee['id']] = [] }

    # Populate a dictionary where each key is the reviewee, and the value is
    # a list of all the reviewers. This may leave some entries empty, which
    # means they have no reviewers.
    peer_reviews = PeerReview.where(reviewer_id: reviewer_ids)
    peer_reviews.each do |peer_review|
      reviewee_group_id = peer_review.result.submission.grouping.id
      peer_review_map[reviewee_group_id].push(peer_review.reviewer.id)
    end

    return peer_review_map
  end

  def populate_all_group_names(reviewer_groups, reviewee_groups)
    # We need to get every possible group so we have a big map of everyone that
    # is present in both tables.
    unique_group_ids = {}
    reviewer_groups.each { |reviewer| unique_group_ids[reviewer['id']] = 0 }
    reviewee_groups.each { |reviewee| unique_group_ids[reviewee['id']] = 0 }

    # Compress them into a single list so we can pass it off as a query.
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

  def assign_groups
    @assignment = Assignment.find(params[:assignment_id])
    selected_reviewer_group_ids = params[:selectedReviewerGroupIds]
    selected_reviewee_group_ids = params[:selectedRevieweeGroupIds]
    action_string = params[:actionString]

    if selected_reviewer_group_ids.size == 0
      render text: 'Cannot have an empty list of reviewers', status: 400
      return
    elsif selected_reviewee_group_ids.size == 0
      render text: 'Cannot have an empty list of reviewees', status: 400
      return
    end

    reviewer_groups = Grouping.where(id: selected_reviewer_group_ids)
    reviewee_groups = Grouping.where(id: selected_reviewee_group_ids)

    case action_string
      when 'random_assign'
        randomly_assign(reviewer_groups, reviewee_groups)
      when 'assign'
        assign(reviewer_groups, reviewee_groups)
      when 'unassign'
        unassign(reviewer_groups, reviewee_groups)
      else
        render text: 'Unexpected action type', status: 400
        return
    end

    head :ok
  end

  def randomly_assign(reviewer_groups, reviewee_groups)
    # TODO
  end

  def assign(reviewer_groups, reviewee_groups)
    # TODO - Do not allow assigning if the user is already assigned
    reviewer_groups.each do |reviewer_group|
      reviewee_groups.each do |reviewee_group|
        # TODO - is this okay to do? should the result be cached? or does rails do this for us transparently?
        result = reviewee_group.current_submission_used.get_latest_result
        PeerReview.create(reviewer: reviewer_group, result: result)
      end
    end
  end

  def unassign(reviewer_groups, reviewee_groups)
    # TODO
  end

  def groupings_with_assoc(assignment, options = {})
    grouping_ids = options[:grouping_ids]
    includes = options[:includes] || GROUPING_ASSOC

    groupings = assignment.groupings.includes(includes)
    grouping_ids ? groupings.where(id: grouping_ids) : groupings
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
