# A controller responsible for CRUD operations for the Section model
module Api
  class SectionsController < MainApiController
    def destroy
      @section = record

      if @section.has_students?
        render 'shared/http_status',
               locals: { code: '404', message: t('sections.destroy.not_empty'), status: :conflict }
      else
        @section.assessment_section_properties.each(&:destroy)
        @section.destroy
        render 'shared/http_status',
               locals: { code: '200', message: t('sections.destroy.success'), status: :ok }
      end
    end
  end
end
