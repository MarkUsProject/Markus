class PeerReviewsController < ApplicationController
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

    if @current_user.ta?
      render json: get_summaries_table_info(@assignment,
                                            @current_user.id)
    else
      render json: get_summaries_table_info(@assignment)
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
