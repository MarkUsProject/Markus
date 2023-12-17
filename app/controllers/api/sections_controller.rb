module Api
  # Api controller responsible for CRUD operations for the Section model
  class SectionsController < MainApiController
    def create
      section = current_course.sections.new(section_params)
      if section.save
        render 'shared/http_status',
               locals: { code: '201', message: HttpStatusHelper::ERROR_CODE['message']['201'] }, status: :created
      else
        render 'shared/http_status', locals: { code: '422', message:
          HttpStatusHelper::ERROR_CODE['message']['422'] }, status: :unprocessable_entity
      end
    end

    def destroy
      @section = record

      if @section.has_students?
        render 'shared/http_status',
               locals: { code: :conflict, message: t('sections.destroy.not_empty') },
               status: :conflict
      else
        @section.assessment_section_properties.each(&:destroy)
        @section.destroy
        render 'shared/http_status',
               locals: { code: '200', message: t('sections.destroy.success') },
               status: :ok
      end
    end

    def section_params
      params.require(:section).permit(:name)
    end
  end
end
