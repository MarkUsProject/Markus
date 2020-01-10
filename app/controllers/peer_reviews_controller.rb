class PeerReviewsController < ApplicationController
  include GroupsHelper
  include PeerReviewHelper
  include RandomAssignHelper

  before_action :set_peer_review, only: [:show, :edit, :update, :destroy]

  before_action :authorize_only_for_admin, except: [:list_reviews, :show_reviews, :show_result]
  before_action :authorize_for_user, only: [:list_reviews, :show_reviews, :show_result]

  layout 'assignment_content'

  def index
    @assignment = Assignment.find(params[:assignment_id])

    unless @assignment.is_peer_review?
      redirect_to edit_assignment_path(@assignment)
      return
    end

    @section_column = ''
    if Section.all.size > 0
      @section_column = "{
        id: 'section',
        content: '#{Section.model_name.human}',
        sortable: true
      },"
    end
  end

  def populate
    @assignment = Assignment.find(params[:assignment_id])

    reviewer_groups = @assignment.all_grouping_data
    reviewee_groups = @assignment.parent_assignment.all_grouping_data

    reviewee_to_reviewers_map = create_map_reviewee_to_reviewers(reviewer_groups, reviewee_groups)
    id_to_group_names_map = create_map_group_id_to_name(reviewer_groups, reviewee_groups)
    num_reviews_map = PeerReview.group(:reviewer_id)
                                .having(reviewer_id: reviewer_groups[:groups].map { |g| g[:_id] })
                                .count

    render json: {
      reviewer_groups: reviewer_groups,
      reviewee_groups: reviewee_groups,
      reviewee_to_reviewers_map: reviewee_to_reviewers_map,
      id_to_group_names_map: id_to_group_names_map,
      num_reviews_map: num_reviews_map,
      sections: Hash[Section.all.pluck(:id, :name)]
    }
  end

  # Get data for all reviews for a given reviewer.
  def list_reviews
    assignment = Assignment.find(params[:assignment_id]).pr_assignment
    if current_user.is_a_reviewer?(assignment)
      # grab only the groupings of reviewees that this reviewer
      # is responsible for
      grouping = current_user.grouping_for(assignment.id)
      groupings = grouping.peer_reviews_to_others
                          .joins(result: { grouping: :group })
                          .pluck('results.id', 'groups.group_name', 'results.marking_state')
                          .map { |id, name, state| { id: id, group_name: name, state: state } }
    else
      groupings = []
    end

    render json: groupings
  end

  def show_reviews
    assignment = Assignment.find(params[:assignment_id])
    # grab the first peer review of the reviewee group
    pr = @current_user.grouping_for(assignment.id).peer_reviews.first

    if !pr.nil?
      redirect_to show_result_assignment_peer_review_path(assignment.id, id: pr.id)
    else
      render 'shared/http_status',
             formats: [:html],
             locals: { code: '404', message: HttpStatusHelper::ERROR_CODE['message']['404'] },
             status: 404,
             layout: false
    end
  end

  def show_result
    pr = PeerReview.find(params[:id])

    redirect_to view_marks_assignment_result_path(params[:assignment_id], pr.result_id)
  end

  def assign_groups
    @assignment = Assignment.find(params[:assignment_id])
    selected_reviewer_group_ids = params[:selectedReviewerGroupIds] || []
    selected_reviewee_group_ids = params[:selectedRevieweeGroupIds] || []
    reviewers_to_remove_from_reviewees_map = params[:selectedReviewerInRevieweeGroups] || {}
    action_string = params[:actionString]
    num_groups_for_reviewers = params[:numGroupsToAssign].to_i

    if action_string == 'assign' || action_string == 'random_assign'
      if selected_reviewer_group_ids.empty?
        flash_now(:error, t('peer_reviews.errors.select_a_reviewer'))
        head 400
        return
      elsif selected_reviewee_group_ids.empty?
        flash_now(:error, t('peer_reviews.errors.select_a_reviewee'))
        head 400
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
          head 400
          return
        end
      when 'assign'
        reviewer_groups = Grouping.where(id: selected_reviewer_group_ids)
        reviewee_groups = Grouping.where(id: selected_reviewee_group_ids)
        begin
          PeerReview.assign(reviewer_groups, reviewee_groups)
        rescue ActiveRecord::RecordInvalid => e
          flash_now(:error, e.message)
          head 400
          return
        rescue SubmissionsNotCollectedException
          flash_now(:error, t('peer_reviews.errors.collect_submissions_first'))
          head 400
          return
        end
      when 'unassign'
        PeerReview.unassign(selected_reviewee_group_ids, reviewers_to_remove_from_reviewees_map)
      else
        head 400
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
      data = process_file_upload
    rescue Psych::SyntaxError => e
      flash_message(:error, t('upload_errors.syntax_error', error: e.to_s))
    rescue StandardError => e
      flash_message(:error, e.message)
    else
      if data[:type] == '.csv'
        assignment = Assignment.find(params[:assignment_id])
        result = PeerReview.from_csv(assignment, data[:file].read)
        flash_message(:error, result[:invalid_lines]) unless result[:invalid_lines].empty?
        flash_message(:success, result[:valid_lines]) unless result[:valid_lines].empty?
      end
    end
    redirect_to action: 'index', assignment_id: params[:assignment_id]
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
