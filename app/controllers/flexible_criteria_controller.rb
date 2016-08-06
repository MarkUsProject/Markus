class FlexibleCriteriaController < ApplicationController

  before_filter      :authorize_only_for_admin

  def download
    @assignment = Assignment.find(params[:assignment_id])
    criteria = @assignment.get_criteria(:all, :flexible)
    file_out = MarkusCSV.generate(criteria) do |criterion|
      [criterion.name, criterion.max_mark, criterion.description]
    end
    send_data(file_out,
              type: 'text/csv',
              filename: "#{@assignment.short_identifier}_flexible_criteria.csv",
              disposition: 'inline')
  end

  def upload
    file = params[:upload][:flexible]
    @assignment = Assignment.find(params[:assignment_id])
    encoding = params[:encoding]
    if request.post? && !file.blank?
      FlexibleCriterion.transaction do
        result = MarkusCSV.parse(file.read, encoding: encoding) do |row|
          next if CSV.generate_line(row).strip.empty?
          FlexibleCriterion.create_or_update_from_csv_row(row, @assignment)
        end
        unless result[:invalid_lines].empty?
          flash_message(:error, result[:invalid_lines])
        end
        unless result[:valid_lines].empty?
          flash_message(:success, result[:valid_lines])
        end
      end
    end
    redirect_to action: 'index', assignment_id: @assignment.id
  end
end
