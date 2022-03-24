module Admin
  class UsersController < ApplicationController
    DEFAULT_FIELDS = [:id, :user_name, :email, :id_number, :type, :first_name, :last_name].freeze
    before_action { authorize! }

    respond_to :html
    layout 'assignment_content'

    def index
      respond_to do |format|
        format.html
        format.json { render json: visible_users.order(:created_at).to_json(only: DEFAULT_FIELDS) }
      end
    end

    protected

    def implicit_authorization_target
      OpenStruct.new policy_class: Admin::UserPolicy
    end

    private

    # Do not make AutotestUser users visible
    def visible_users
      User.where.not(type: :AutotestUser)
    end
  end
end
