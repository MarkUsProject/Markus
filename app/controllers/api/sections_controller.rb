module Api
  # API controller for sections
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

    def section_params
      params.require(:section).permit(:name)
    end
  end
end
