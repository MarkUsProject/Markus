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
    @assignment = Assignment.find(params[:assignment_id])
    reviewer_groups = get_groupings_table_info
    reviewee_groups = get_groupings_table_info(@assignment.parent_assignment)
    render json: [reviewer_groups, reviewee_groups]
  end

  def assign_groups
    @assignment = Assignment.find(params[:assignment_id])
    render json: ['test']
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
