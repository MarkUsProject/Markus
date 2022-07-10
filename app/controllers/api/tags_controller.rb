module Api
  # Api controller for tags
  class TagsController < ApplicationController
    TAG_FIELDS = [:tag, :name, :description].freeze
    DEFAULT_FIELDS = [:id, :result_id, :assignment_id, :grouping_id, *TAG_FIELDS].freeze

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
      tag_params = params.require(:tag).permit(:name, :description)
      new_tag = Tag.new(tag_params.merge(role: current_role,
                                         assessment: Assessment.find_by(id: params[:assignment_id])))

      if new_tag.save && params[:grouping_id]
        grouping = Grouping.find(params[:grouping_id])
        grouping.tags << new_tag
      end

      respond_with new_tag, location: -> { request.headers['Referer'] || root_path }
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
