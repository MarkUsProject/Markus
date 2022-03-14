module Admin
  class MainAdminController < ApplicationController
    skip_verify_authorized only: [:index]

    respond_to :html
    layout 'main'

    def index
      render :index
    end
  end
end
