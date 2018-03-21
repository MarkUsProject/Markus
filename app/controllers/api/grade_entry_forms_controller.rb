module Api

  class GradeEntryFormsController < MainApiController

    # Sends the contents of the specified grade entry form
    # Requires: id
    def show
      grade_entry_form = GradeEntryForm.find(params[:id])
      send_data grade_entry_form.export_as_csv,
                type: 'text/csv',
                filename: "#{grade_entry_form.short_identifier}_grades_report.csv",
                disposition: 'inline'
    rescue ActiveRecord::RecordNotFound => e
      # could not find grade entry form
      render 'shared/http_status', locals: { code: '404', message: e }, status: 404
    end

  end

end
