module Api
  # API controller for Courses
  class CoursesController < MainApiController
    DEFAULT_FIELDS = [:name, :is_hidden, :display_name].freeze

    def index
      users = get_collection(Course) || return
      respond_to do |format|
        format.xml { render xml: users.to_xml(only: DEFAULT_FIELDS, root: 'courses', skip_types: 'true') }
        format.json { render json: users.to_json(only: DEFAULT_FIELDS) }
      end
    end
  end
end
