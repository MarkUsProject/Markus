module Api
  # Api controller for tags
  # Uses Rails' RESTful routes (check 'rake routes' for the configured routes)
  class TagsController < MainApiController
    def index
      assignment = Assignment.find_by(id: params[:assignment_id])

      respond_to do |format|
        parent = assignment || current_course
        tags = parent.tags.includes(:role, :groupings).order(:name)

        tag_info = tags.map do |tag|
          {
            id: tag.id,
            name: tag.name,
            description: tag.description,
            creator: tag.role.display_name,
            use: tag.groupings.size
          }
        end
        format.xml do
          render xml: tag_info
        end
        format.json do
          render json: tag_info
        end
      end
    end

    # Creates a new instance of the tag.
    def create
      assignment = current_course.assignments.find_by(id: params[:assignment_id])
      new_tag = Tag.create!(course: current_course, role: current_role, assessment: assignment, **self.tag_params)
      if params[:grouping_id]
        grouping = assignment.groupings.find(params[:grouping_id])
        grouping.tags << new_tag
      end
    rescue StandardError => e
      render 'shared/http_status', locals: { code: '422', message: e.to_s }, status: :unprocessable_content
    else
      render 'shared/http_status',
             locals: { code: '201', message: HttpStatusHelper::ERROR_CODE['message']['201'] }, status: :created
    end

    def update
      tag = Tag.find_by(id: params[:id])
      if tag.nil?
        render 'shared/http_status', locals: { code: '404', message: I18n.t('tags.not_found') }, status: :not_found
      else
        begin
          tag.update!(**self.tag_params)
        rescue StandardError => e
          render 'shared/http_status', locals: { code: '422', message: e.to_s }, status: :unprocessable_content
        else
          render 'shared/http_status',
                 locals: { code: '200', message: HttpStatusHelper::ERROR_CODE['message']['200'] }, status: :ok
        end
      end
    end

    def destroy
      tag = Tag.find_by(id: params[:id])
      if tag.nil?
        render 'shared/http_status', locals: { code: '404', message: I18n.t('tags.not_found') }, status: :not_found
      else
        tag.destroy!
        render 'shared/http_status',
               locals: { code: '200', message: HttpStatusHelper::ERROR_CODE['message']['200'] }, status: :ok
      end
    end

    private

    def tag_params
      params.permit(:name, :description)
    end
  end
end
