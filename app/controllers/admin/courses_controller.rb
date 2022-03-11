module Admin
  # Manages actions relating to editing and modifying
  # courses.
  class CoursesController < ApplicationController
    before_action { authorize! }

    respond_to :html
    layout 'layouts/assignment_content'

    def index
      render :index
    end
  end
end
