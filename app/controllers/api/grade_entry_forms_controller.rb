module Api
  class GradeEntryFormsController < MainApiController
    DEFAULT_FIELDS = [:id, :short_identifier, :description, :due_date, :is_hidden, :show_total].freeze

    # Sends the contents of the specified grade entry form
    # Requires: id
    def show
      grade_entry_form = record
      send_data grade_entry_form.export_as_csv(current_role),
                type: 'text/csv',
                filename: "#{grade_entry_form.short_identifier}_grades_report.csv",
                disposition: 'inline'
    rescue ActiveRecord::RecordNotFound => e
      # could not find grade entry form
      render 'shared/http_status', locals: { code: '404', message: e }, status: :not_found
    end

    def index
      grade_entry_forms = get_collection(current_course.grade_entry_forms) || return

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
    #   :short_identifier, :description
    # Optional:
    #   :description, :due_date, :is_hidden
    #   grade_entry_items:
    #     :name, :out_of, :bonus
    def create
      if has_missing_params?([:short_identifier])
        # incomplete/invalid HTTP params
        render 'shared/http_status', locals: { code: '422', message:
          HttpStatusHelper::ERROR_CODE['message']['422'] }, status: :unprocessable_content
        return
      end

      # check if there is an existing assignment
      form = current_course.grade_entry_forms.find_by(short_identifier: params[:short_identifier])
      unless form.nil?
        render 'shared/http_status', locals: { code: '409', message:
          'Grade Entry Form already exists' }, status: :conflict
        return
      end

      ApplicationRecord.transaction do
        create_params = params.permit(*DEFAULT_FIELDS)
        create_params[:is_hidden] ||= false
        create_params[:description] ||= ''
        create_params[:course_id] = params[:course_id]
        new_form = GradeEntryForm.new(create_params)
        unless new_form.save
          render 'shared/http_status', locals: { code: '422', message:
            new_form.errors.full_messages.first }, status: :unprocessable_content
          raise ActiveRecord::Rollback
        end

        params[:grade_entry_items]&.each&.with_index do |column_params, i|
          column_params = column_params.permit(:name, :out_of, :bonus).to_h.symbolize_keys
          grade_item = new_form.grade_entry_items.build(**column_params, position: i + 1)
          unless grade_item.save
            render 'shared/http_status', locals: { code: '422', message:
              grade_item.errors.full_messages.first }, status: :unprocessable_content
            raise ActiveRecord::Rollback
          end
        end
        render 'shared/http_status', locals: { code: '201', message:
          HttpStatusHelper::ERROR_CODE['message']['201'] }, status: :created
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
      form = record
      if form.nil?
        render 'shared/http_status', locals: { code: '404', message:
          'Grade Entry Form not found' }, status: :not_found
        return
      end

      ApplicationRecord.transaction do
        update_params = params.permit(*DEFAULT_FIELDS)
        unless form.update(update_params)
          render 'shared/http_status', locals: { code: '500', message:
            form.errors.full_messages.first }, status: :internal_server_error
          raise ActiveRecord::Rollback
        end

        position = form.grade_entry_items.count
        params[:grade_entry_items]&.each do |column_params|
          if column_params[:id].nil?
            column_params = column_params.permit(:name, :out_of, :bonus).to_h.symbolize_keys
            grade_item = form.grade_entry_items.build(**column_params, position: position += 1)
            unless grade_item.save
              render 'shared/http_status', locals: { code: '500', message:
                grade_item.errors.full_messages.first }, status: :internal_server_error
              raise ActiveRecord::Rollback
            end
          else
            column_params = column_params.permit(:id, :name, :out_of, :bonus).to_h.symbolize_keys
            grade_item = form.grade_entry_items.where(id: column_params[:id]).first
            if grade_item.nil?
              render 'shared/http_status', locals: { code: '404', message:
                "Grade Entry Item with id=#{column_params[:id]} not found" }, status: :not_found
              raise ActiveRecord::Rollback
            end
            unless grade_item.update(column_params)
              render 'shared/http_status', locals: { code: '500', message:
                grade_item.errors.full_messages.first }, status: :internal_server_error
              raise ActiveRecord::Rollback
            end
          end
        end
        render 'shared/http_status', locals: { code: '200', message:
          HttpStatusHelper::ERROR_CODE['message']['200'] }, status: :ok
      end
    end

    def update_grades
      if has_missing_params?([:user_name, :grade_entry_items])
        # incomplete/invalid HTTP params
        render 'shared/http_status', locals: { code: '422', message:
          HttpStatusHelper::ERROR_CODE['message']['422'] }, status: :unprocessable_content
        return
      end

      grade_entry_form = record

      grade_entry_student = grade_entry_form.grade_entry_students
                                            .joins(:user)
                                            .where('users.user_name': params[:user_name])
                                            .first

      if grade_entry_student.nil?
        # There is no student with that user_name
        render 'shared/http_status', locals: { code: '422', message:
          'There is no student with that user_name' }, status: :unprocessable_content
        return
      end

      Grade.transaction do
        params[:grade_entry_items].each do |item, score|
          grade_entry_item = GradeEntryItem.find_by(name: item, assessment_id: params[:id])

          if grade_entry_item.nil?
            # There is no such grade entry item
            render 'shared/http_status', locals: { code: '422', message:
              "There is no grade entry item named #{item}" }, status: :unprocessable_content
            raise ActiveRecord::Rollback
          end
          grade = grade_entry_student.grades.find_or_create_by(grade_entry_item_id: grade_entry_item.id)
          grade.update(grade: score)
        end
        if grade_entry_student.save
          render 'shared/http_status', locals: { code: '200', message:
            HttpStatusHelper::ERROR_CODE['message']['200'] }, status: :ok
        else
          # Some error occurred (including invalid mark)
          render 'shared/http_status', locals: { code: '500', message:
            grade_entry_student.errors.full_messages.first }, status: :internal_server_error
          raise ActiveRecord::Rollback
        end
      end
    end

    def destroy
      # check if the grade entry form exists
      grade_entry_form = record
      if grade_entry_form.nil?
        render 'shared/http_status', locals: { code: '404', message:
          'Grade Entry Form not found' }, status: :not_found
        return
      end
      # delete the grade entry form
      begin
        grade_entry_form.destroy!
        render 'shared/http_status',
               locals: { code: '200',
                         message: 'Grade Entry Form successfully deleted' }, status: :ok
      rescue ActiveRecord::RecordNotDestroyed
        render 'shared/http_status',
               locals: { code: :conflict,
                         message: 'Grade Entry Form contains non-nil grades' }, status: :conflict
      end
    end
  end
end
