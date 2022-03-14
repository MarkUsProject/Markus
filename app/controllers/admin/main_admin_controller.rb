module Admin
  class MainAdminController < ApplicationController
    before_action { authorize! }

    respond_to :html
    layout 'main'

    def index
      render :index
    end

    protected

    def implicit_authorization_target
      OpenStruct.new policy_class: MainAdminPolicy
    end
  end
end
