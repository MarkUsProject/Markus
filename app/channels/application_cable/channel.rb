module ApplicationCable
  class Channel < ActionCable::Channel::Base
    include ActionPolicy::Behaviour

    authorize :role, through: :current_role
    authorize :real_user, through: :real_user
    before_subscribe :authorize_channel

    private

    def authorize_channel
      if current_role.nil?
        reject
        return
      end
      authorize! to: authorization_rule, with: authorization_policy
    rescue ActionPolicy::Unauthorized
      reject
    end

    def implicit_authorization_target
      nil
    end

    def authorization_policy
      nil
    end

    def authorization_rule
      raise NotImplementedError
    end

    def current_role
      Role.find_by(user: current_user, course: course)
    end

    def real_user
      connection.real_user
    end

    def course
      Course.find_by(id: params[:course_id])
    end
  end
end
