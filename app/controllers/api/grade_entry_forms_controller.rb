module Api

  class GradeEntryFormsController < MainApiController

    DEFAULT_FIELDS = [:id, :short_identifier, :description, :date, :is_hidden].freeze

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

    def index
      grade_entry_forms = get_collection(GradeEntryForm.includes(:grade_entry_items)) || return

      include_args = { only: DEFAULT_FIELDS, include: { grade_entry_items: { only: [:name, :out_of] } } }

      respond_to do |format|
        format.xml do
          xml = grade_entry_forms.to_xml(**include_args, root: 'grade_entry_forms', skip_types: 'true')
          render xml: xml
        end
        format.json { render json: grade_entry_forms.to_json(include_args) }
      end
    end

    def update_grades
      if has_missing_params?([:user_name, :grade_entry_items])
        # incomplete/invalid HTTP params
        render 'shared/http_status', locals: { code: '422', message:
          HttpStatusHelper::ERROR_CODE['message']['422'] }, status: 422
        return
      end

      begin
        grade_entry_form = GradeEntryForm.find(params[:id])
      rescue ActiveRecord::RecordNotFound => e
        # could not find grade entry form
        render 'shared/http_status', locals: { code: '404', message: e }, status: 404
        return
      end

      grade_entry_student = grade_entry_form.grade_entry_students
                                            .joins(:user)
                                            .where('users.user_name': params[:user_name])
                                            .first

      if grade_entry_student.nil?
        # There is no student with that user_name
        render 'shared/http_status', locals: { code: '422', message:
          'There is no student with that user_name' }, status: 422
        return
      end

      Grade.transaction do
        params[:grade_entry_items].each do |item, score|
          grade_entry_item = GradeEntryItem.find_by(name: item, grade_entry_form_id: params[:id])

          if grade_entry_item.nil?
            # There is no such grade entry item
            render 'shared/http_status', locals: { code: '422', message:
              "There is no grade entry item named #{item}" }, status: 422
            raise ActiveRecord::Rollback
          end
          grade = grade_entry_student.grades.find_or_create_by(grade_entry_item_id: grade_entry_item.id)
          grade.update(grade: score)
        end
        if grade_entry_student.save
          render 'shared/http_status', locals: { code: '200', message:
            HttpStatusHelper::ERROR_CODE['message']['200'] }, status: 200
        else
          # Some error occurred (including invalid mark)
          render 'shared/http_status', locals: { code: '500', message:
            grade_entry_student.errors.full_messages.first }, status: 500
          raise ActiveRecord::Rollback
        end
      end
    end
  end
end
