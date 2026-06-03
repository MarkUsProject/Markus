module Admin
  class UsersController < ApplicationController
    DEFAULT_FIELDS = [:id, :user_name, :email, :id_number, :type, :first_name, :last_name].freeze
    SEARCHABLE_FIELDS = %w[user_name first_name last_name email id_number].freeze
    before_action { authorize! }

    respond_to :html
    layout 'assignment_content'

    def index
      respond_to do |format|
        format.html
        format.json do
          users_scope = visible_users

          if params[:filtered].present?
            JSON.parse(params[:filtered]).each do |f|
              next if f['value'].blank?

              if SEARCHABLE_FIELDS.include?(f['id'])
                term = "%#{User.sanitize_sql_like(f['value'].strip)}%"
                users_scope = users_scope.where("#{f['id']} LIKE ?", term)
              elsif f['id'] == 'type' && f['value'] != 'all'
                users_scope = users_scope.where(type: f['value'])
              end
            end
          end

          if params[:sorted].present?
            sort_config = JSON.parse(params[:sorted]).first
            if sort_config
              direction = sort_config['desc'] ? 'DESC' : 'ASC'
              column = if %w[user_name first_name last_name email id_number type].include?(sort_config['id'])
                         sort_config['id']
                       else
                         'user_name'
                       end
              users_scope = users_scope.order("#{column} #{direction}")
            end
          else
            users_scope = users_scope.order(:user_name)
          end

          per_page = (params[:per_page] || 100).to_i
          current_page = (params[:page] || 1).to_i
          total_count = users_scope.count
          calculated_pages = (total_count.to_f / per_page).ceil
          offset_value = (current_page - 1) * per_page
          records = users_scope.limit(per_page).offset(offset_value)

          render json: {
            users: records.pluck_to_hash(:id, :user_name, :first_name, :last_name, :email, :id_number, :type),
            total_pages: calculated_pages > 0 ? calculated_pages : 1
          }
        end
      end
    end

    def new
      @user = User.new
    end

    def create
      user_params = params.require(:user)
      user_params[:type] = nil unless [EndUser.name, AdminUser.name].include? user_params[:type]
      @user = User.create(user_params.permit(*DEFAULT_FIELDS))
      respond_with @user, location: -> { admin_users_path }
    end

    def edit
      @user = record
    end

    def update
      @user = record
      user_params = params.require(@user.model_name.to_s.underscore)
      @user.update(user_params.permit(:user_name, :email, :id_number, :first_name, :last_name))
      respond_with @user, location: -> { edit_admin_user_path(@user) }
    end

    def upload
      begin
        data = process_file_upload(['.csv'])
      rescue StandardError => e
        flash_message(:error, e.message)
      else
        @current_job = UploadUsersJob.perform_later(EndUser,
                                                    data[:contents],
                                                    data[:encoding])
        session[:job_id] = @current_job.job_id
      end
      redirect_to action: 'index'
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

    def flash_interpolation_options
      { resource_name: @user.user_name.presence || @user.model_name.human,
        errors: @user.errors.full_messages.join('; ') }
    end
  end
end
