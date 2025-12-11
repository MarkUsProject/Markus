module Api
  # Api controller responsible for CRUD operations for the Section model
  class SectionsController < MainApiController
    def index
      sections = current_course.sections
      respond_to do |format|
        format.json { render json: sections }
        format.xml { render xml: sections }
      end
    end

    def show
      section = record
      respond_to do |format|
        format.json { render json: section }
        format.xml { render xml: section }
      end
    end

    def update
      section = record
      if section.update(params.permit(:name))
        render 'shared/http_status', locals: { code: '200', message:
          t('sections.update.success', name: section.name) }, status: :ok
      else
        render 'shared/http_status', locals: { code: '400', message:
          t('sections.update.error', name: section.name) }, status: :bad_request
      end
    end

    def create
      section = current_course.sections.new(section_params)
      if section.save
        render 'shared/http_status',
               locals: { code: '201', message: HttpStatusHelper::ERROR_CODE['message']['201'] }, status: :created
      else
        render 'shared/http_status', locals: { code: '422', message:
          HttpStatusHelper::ERROR_CODE['message']['422'] }, status: :unprocessable_content
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
