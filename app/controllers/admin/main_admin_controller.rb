module Admin
  class MainAdminController < ApplicationController
    skip_verify_authorized only: [:index]

    respond_to :html
    layout 'assignment_content'

    def index
      render inline: '<h1>Title</h1>'
    end
  end
end
