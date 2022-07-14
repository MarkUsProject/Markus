class LtiDeployment < ApplicationRecord
  belongs_to :course, optional: true
  belongs_to :lti_client
  validates :external_deployment_id, uniqueness: { scope: :lti_client }

  def get_students
    auth_data = lti_client.get_oauth_token(['https://purl.imsglobal.org/spec/lti-nrps/scope/contextmembership.readonly'])
    names_service = LtiService.find_by!(lti_deployment: self, service_type: 'namesroles')
    membership_uri = URI(names_service.url)
    membership_uri.query = URI.encode_www_form(role: 'http://purl.imsglobal.org/vocab/lis/v2/membership#Learner')
    req = Net::HTTP::Get.new(membership_uri)
    req['Authorization'] = "#{auth_data['token_type']} #{auth_data['access_token']}"
    http = Net::HTTP.new(membership_uri.host, membership_uri.port)

    res = http.request(req)
    member_info = JSON.parse(res.body)
    member_info['members'].each do |member|
      if member['status'] == 'Inactive'
        next
      end
      user = EndUser.find_by(user_name: member['lis_person_sourcedid'])
      if user.nil?
        user = EndUser.create!(user_name: member['lis_person_sourcedid'], first_name: member['given_name'],
                               last_name: member['family_name'])
        Student.create!(user: user, course: course)
      end
      LtiUser.find_or_create_by(user: user, lti_client: lti_client, lti_user_id: member['user_id'])
    end
  end
end
