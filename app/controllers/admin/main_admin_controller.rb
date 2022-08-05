module Admin
  class MainAdminController < ApplicationController
    before_action { authorize! }

    respond_to :html
    layout 'assignment_content'

    def index
      @dashboards = [{ name: t('resque.dashboard'), path: admin_resque_path }]
      if Settings.rails_performance.enabled
        @dashboards << { name: t('rails_performance.dashboard'), path: admin_performance_path }
      end
      render :index
    end

    protected

    def implicit_authorization_target
      OpenStruct.new policy_class: MainAdminPolicy
    end
  end
end
