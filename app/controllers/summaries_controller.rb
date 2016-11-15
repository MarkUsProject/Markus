class SummariesController < ApplicationController
  include SummariesHelper

  before_filter  :authorize_only_for_admin

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

    @criteria = @assignment.get_criteria
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
end
