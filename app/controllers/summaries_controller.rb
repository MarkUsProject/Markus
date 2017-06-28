class SummariesController < ApplicationController
  include SummariesHelper
  include SubmissionsHelper

  before_filter  :authorize_for_ta_and_admin

  def index
    @assignment = Assignment.find(params[:assignment_id])
    @tas = @assignment.ta_memberships.includes(grouping: [:tas]).uniq.pluck(:user_name)

    @section_column = ''
    if Section.all.size > 0
      @section_column = "{
        id: 'section',
        content: '#{Section.model_name.human}',
        sortable: true
      },"
    end

    @criteria = @assignment.get_criteria
  end

  def populate
    @assignment = Assignment.find(params[:assignment_id])
    if @current_user.ta?
      ta = Ta.find(grader_id)
      groupings = @assignment.groupings
                    .includes(:assignment,
                              :group,
                              :grace_period_deductions,
                              current_result: :marks,
                              accepted_student_memberships: :user)
                    .select do |g|
        g.non_rejected_student_memberships.size > 0 and
          ta.is_assigned_to_grouping?(g.id)
      end
    else
      groupings = @assignment.groupings
                    .includes(:assignment,
                              :group,
                              :grace_period_deductions,
                              current_result: :marks,
                              accepted_student_memberships: :user)
                    .select { |g| g.non_rejected_student_memberships.size > 0 }
    end

    @render_bonus_deductions_column = false
    groupings.map do |grouping|
      result = grouping.current_result
      if grouping.total_extra_points(result) > 0
        @render_bonus_deductions_column = true
      end
    end
    render json: get_summaries_table_info(@assignment, groupings, @render_bonus_deductions_column)
  end
end
