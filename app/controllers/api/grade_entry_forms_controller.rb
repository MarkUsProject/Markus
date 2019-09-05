module Api

  class GradeEntryFormsController < MainApiController

    DEFAULT_FIELDS = [:id, :short_identifier, :description, :date, :is_hidden, :show_total].freeze

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

      include_args = { only: DEFAULT_FIELDS, include: { grade_entry_items: { only: [:id, :name, :out_of] } } }

      respond_to do |format|
        format.xml do
          xml = grade_entry_forms.to_xml(**include_args, root: 'grade_entry_forms', skip_types: 'true')
          render xml: xml
        end
        format.json { render json: grade_entry_forms.to_json(include_args) }
      end
    end

    # create a new grade entry form
    # Requires:
    #   :short_identifier
    # Optional:
    #   :description, :date, :is_hidden
    #   grade_entry_items:
    #     :name, :out_of, :bonus
    def create
      if has_missing_params?([:short_identifier])
        # incomplete/invalid HTTP params
        render 'shared/http_status', locals: { code: '422', message:
          HttpStatusHelper::ERROR_CODE['message']['422'] }, status: 422
        return
      end

      # check if there is an existing assignment
      form = GradeEntryForm.find_by_short_identifier(params[:short_identifier])
      unless form.nil?
        render 'shared/http_status', locals: { code: '409', message:
          'Grade Entry Form already exists' }, status: 409
        return
      end

      ApplicationRecord.transaction do
        create_params = params.permit(*DEFAULT_FIELDS)
        create_params[:is_hidden] ||= false
        create_params[:description] ||= ''
        new_form = GradeEntryForm.new(create_params)
        unless new_form.save
          render 'shared/http_status', locals: { code: '500', message:
            new_form.errors.full_messages.first }, status: 500
          raise ActiveRecord::Rollback
        end

        params[:grade_entry_items]&.each&.with_index do |column_params, i|
          column_params = column_params.permit(:name, :out_of, :bonus).to_h.symbolize_keys
          grade_item = new_form.grade_entry_items.build(**column_params, position: i + 1)
          unless grade_item.save
            render 'shared/http_status', locals: { code: '500', message:
              grade_item.errors.full_messages.first }, status: 500
            raise ActiveRecord::Rollback
          end
        end
        render 'shared/http_status', locals: { code: '200', message:
          HttpStatusHelper::ERROR_CODE['message']['200'] }, status: 200
      end
    end

    # create a new grade entry form
    # params:
    #   :short_identifier, :description, :date, :is_hidden
    #   grade_entry_items:
    #     :id, :name, :out_of, :bonus
    #
    # if the grade_entry_items id param is set, an existing item will be
    # updated, otherwise a new grade_entry_item will be created
    def update
      # check if there is an existing assignment
      form = GradeEntryForm.find_by_id(params[:id])
      if form.nil?
        render 'shared/http_status', locals: { code: '404', message:
          'Grade Entry Form not found' }, status: 404
        return
      end

      ApplicationRecord.transaction do
        update_params = params.permit(*DEFAULT_FIELDS)
        unless form.update(update_params)
          render 'shared/http_status', locals: { code: '500', message:
            form.errors.full_messages.first }, status: 500
          raise ActiveRecord::Rollback
        end

        position = form.grade_entry_items.count
        params[:grade_entry_items]&.each do |column_params|
          if column_params[:id].nil?
            column_params = column_params.permit(:name, :out_of, :bonus).to_h.symbolize_keys
            grade_item = form.grade_entry_items.build(**column_params, position: position += 1)
            unless grade_item.save
              render 'shared/http_status', locals: { code: '500', message:
                grade_item.errors.full_messages.first }, status: 500
              raise ActiveRecord::Rollback
            end
          else
            column_params = column_params.permit(:id, :name, :out_of, :bonus).to_h.symbolize_keys
            grade_item = form.grade_entry_items.where(id: column_params[:id]).first
            if grade_item.nil?
              render 'shared/http_status', locals: { code: '404', message:
                "Grade Entry Item with id=#{column_params[:id]} not found" }, status: 404
              raise ActiveRecord::Rollback
            end
            unless grade_item.update(column_params)
              render 'shared/http_status', locals: { code: '500', message:
                grade_item.errors.full_messages.first }, status: 500
              raise ActiveRecord::Rollback
            end
          end
        end
        render 'shared/http_status', locals: { code: '200', message:
          HttpStatusHelper::ERROR_CODE['message']['200'] }, status: 200
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
