module Api
  # Api controller for tags
  # Uses Rails' RESTful routes (check 'rake routes' for the configured routes)
  class TagsController < MainApiController
    DEFAULT_FIELDS = [:id, :name, :description, :creator, :use].freeze

    def index
      @assignment = Assignment.find_by(id: params[:assignment_id])

      respond_to do |format|
        parent = @assignment || current_course
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

    def edit
      @tag = Tag.find(params[:id])
    end

    # Creates a new instance of the tag.
    def create
      params.permit(:name, :description)
      begin
        new_tag = Tag.new(name: params[:name], description: params[:description],
                          course: Course.find_by(id: params[:course_id]),
                          role: current_role, assessment: Assessment.find_by(id: params[:assignment_id]))

        if new_tag.save && params[:grouping_id]
          grouping = Grouping.find(params[:grouping_id])
          grouping.tags << new_tag
        end
      rescue StandardError => e
        render 'shared/http_status', locals: { code: '422', message: e.to_s }, status: :unprocessable_entity
      else
        render 'shared/http_status',
               locals: { code: '201', message: HttpStatusHelper::ERROR_CODE['message']['201'] }, status: :created
      end
    end

    def update
      tag = Tag.find(params[:id])
      tag.update(params.require(:tag).permit(:name, :description))

      respond_with tag, location: -> { request.headers['Referer'] || root_path }
    end

    def destroy
      Tag.find(params[:id]).destroy
      head :ok
    end

    def add_tag
      result = Result.find(params[:result_id])
      tag = Tag.find(params[:id])
      result.submission.grouping.tags << tag
      head :ok
    end

    def remove_tag
      result = Result.find(params[:result_id])
      tag = Tag.find(params[:tag_id])
      result.submission.grouping.tags.destroy(tag)
      head :ok
    end
  end
end
