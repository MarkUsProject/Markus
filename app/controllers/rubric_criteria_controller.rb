class RubricCriteriaController < ApplicationController

  before_filter :authorize_only_for_admin

  def download_csv
    @assignment = Assignment.find(params[:assignment_id])
    file_out = MarkusCSV.generate(@assignment.get_criteria(:all, :rubric)) do |criterion|
      criterion_array = [criterion.name, criterion.max_mark]
      (0..RubricCriterion::RUBRIC_LEVELS - 1).each do |i|
        criterion_array.push(criterion['level_' + i.to_s + '_name'])
      end
      (0..RubricCriterion::RUBRIC_LEVELS - 1).each do |i|
        criterion_array.push(criterion['level_' + i.to_s + '_description'])
      end
      criterion_array
    end
    send_data(file_out,
              type: 'text/csv',
              filename: "#{@assignment.short_identifier}_rubric_criteria.csv",
              disposition: 'attachment')
  end

  def csv_upload
    @assignment = Assignment.find(params[:assignment_id])
    encoding = params[:encoding]
    if params[:csv_upload] && params[:csv_upload][:rubric]
      file = params[:csv_upload][:rubric]
      result = RubricCriterion.transaction do
        MarkusCSV.parse(file.read, encoding: encoding) do |row|
          next if CSV.generate_line(row).strip.empty?
          RubricCriterion.create_or_update_from_csv_row(row, @assignment)
        end
      end
      unless result[:invalid_lines].empty?
        flash_message(:error, result[:invalid_lines])
      end
      unless result[:valid_lines].empty?
        flash_message(:success, result[:valid_lines])
      end
    else
      flash_message(:error, I18n.t('csv.invalid_csv'))
    end
    redirect_to controller: 'criteria', action: 'index', id: @assignment.id
  end
end
