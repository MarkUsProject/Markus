module Admin
  class CoursesController < ApplicationController
    before_action { authorize! }

    respond_to :html
    layout 'assignment_content'

    def index
      respond_to do |format|
        format.html { page_not_found }
        format.js
      end
    end
  end
end
