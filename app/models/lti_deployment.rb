class LtiDeployment < ApplicationRecord
  belongs_to :course, optional: true
  belongs_to :lti_client
  has_many :lti_services, dependent: :destroy
  validates :external_deployment_id, uniqueness: { scope: :lti_client }

  def get_students
    auth_data = lti_client.get_oauth_token(['https://purl.imsglobal.org/spec/lti-nrps/scope/contextmembership.readonly'])
    names_service = self.lti_services.find_by!(service_type: 'namesrole')
    membership_uri = URI(names_service.url)
    membership_uri.query = URI.encode_www_form(role: 'http://purl.imsglobal.org/vocab/lis/v2/membership#Learner')
    req = Net::HTTP::Get.new(membership_uri)
    req['Authorization'] = "#{auth_data['token_type']} #{auth_data['access_token']}"
    http = Net::HTTP.new(membership_uri.host, membership_uri.port)

    res = http.request(req)
    member_info = JSON.parse(res.body)
    user_data = member_info['members'].filter_map do |user|
      unless user['status'] == 'Inactive'
        { user_name: user['lis_person_sourcedid'],
          first_name: user['given_name'],
          last_name: user['family_name'],
          display_name: user['name'],
          email: user['email'],
          lti_user_id: user['user_id'],
          time_zone: Time.zone.name }
      end
    end
    if user_data.empty?
      return
    end
    users = EndUser.upsert_all(user_data.map { |user| user.except(:lti_user_id) },
                               returning: %w[id user_name], unique_by: :user_name)

    users.each do |user|
      user[:lti_user_id] = user_data.find do |data|
                             data['user_name'] == user[:user_name]
                           end [:lti_user_id]
    end
    Student.upsert_all(users.map do |user|
                         { user_id: user['id'], course_id: course.id, type: 'Student' }
                       end, unique_by: :index_roles_on_user_id_and_course_id)
    LtiUser.upsert_all(users.map do |user|
                         { user_id: user['id'], lti_client_id: lti_client.id, lti_user_id: user[:lti_user_id] }
                       end,
                       unique_by: %i[user_id lti_client_id])
  end
end
