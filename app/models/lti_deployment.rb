class LtiDeployment < ApplicationRecord
  belongs_to :course, optional: true
  belongs_to :lti_client
  has_many :lti_services, dependent: :destroy
  has_many :lti_line_items, dependent: :destroy
  validates :external_deployment_id, uniqueness: { scope: :lti_client }
  # See LTI documentation for full lists of scopes/claims/roles
  # https://www.imsglobal.org/spec/lti/v1p3
  LTI_SCOPES = { names_role: 'https://purl.imsglobal.org/spec/lti-nrps/scope/contextmembership.readonly',
                 ags_lineitem: 'https://purl.imsglobal.org/spec/lti-ags/scope/lineitem',
                 score: 'https://purl.imsglobal.org/spec/lti-ags/scope/score' }.freeze
  LTI_CLAIMS = { context: 'https://purl.imsglobal.org/spec/lti/claim/context',
                 custom: 'https://purl.imsglobal.org/spec/lti/claim/custom',
                 names_role: 'https://purl.imsglobal.org/spec/lti-nrps/claim/namesroleservice',
                 ags_lineitem: 'https://purl.imsglobal.org/spec/lti-ags/claim/endpoint',
                 deployment_id: 'https://purl.imsglobal.org/spec/lti/claim/deployment_id',
                 user_launch_data: 'https://purl.imsglobal.org/spec/lti/claim/lti1p1' }.freeze
  LTI_ROLES = { learner: 'http://purl.imsglobal.org/vocab/lis/v2/membership#Learner' }.freeze

  # Gets a list of all users in the LMS course associated with this deployment
  # with the learner role and creates roles and LTI IDs for each user.
  def get_students
    auth_data = lti_client.get_oauth_token([LTI_SCOPES[:names_role]])
    names_service = self.lti_services.find_by!(service_type: 'namesrole')
    membership_uri = URI(names_service.url)
    membership_uri.query = URI.encode_www_form(role: LTI_ROLES[:learner])
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
          time_zone: Time.zone.name,
          type: 'EndUser' }
      end
    end
    if user_data.empty?
      return
    end
    users = EndUser.upsert_all(user_data.map { |user| user.except(:lti_user_id) },
                               returning: %w[id user_name], unique_by: :user_name)

    users.each do |user|
      matched_user = user_data.find { |data| data[:user_name] == user['user_name'] }
      user[:lti_user_id] = matched_user[:lti_user_id]
    end
    Student.upsert_all(users.map do |user|
                         { user_id: user['id'], course_id: course.id, type: 'Student' }
                       end, unique_by: :index_roles_on_user_id_and_course_id)
    LtiUser.upsert_all(users.map do |user|
                         { user_id: user['id'], lti_client_id: lti_client.id, lti_user_id: user[:lti_user_id] }
                       end,
                       unique_by: %i[user_id lti_client_id])
  end

  # Creates or updates an assignment in the LMS gradebook for a given assessment.
  def create_or_update_lti_assessment(assessment)
    payload = {
      label: assessment.description,
      resourceId: assessment.short_identifier,
      scoreMaximum: assessment.max_mark.to_f
    }
    auth_data = lti_client.get_oauth_token([LTI_SCOPES[:ags_lineitem]])
    lineitem_service = self.lti_services.find_by!(service_type: 'agslineitem')
    lineitem_uri = URI(lineitem_service.url)
    line_item = self.lti_line_items.find_or_initialize_by(assessment: assessment)
    if line_item.lti_line_item_id?
      req = Net::HTTP::Put.new(line_item.lti_line_item_id)
    else
      req = Net::HTTP::Post.new(lineitem_uri)
    end
    req['Authorization'] = "#{auth_data['token_type']} #{auth_data['access_token']}"
    req.set_form_data(payload)
    http = Net::HTTP.new(lineitem_uri.host, lineitem_uri.port)
    res = http.request(req)
    line_item_data = JSON.parse(res.body)
    line_item.update!(lti_line_item_id: line_item_data['id'])
  end

  # Takes as input an assessment. Sends all *released* marks to
  # the LMS associated with the assignment and the current deployment
  def create_grades(assessment)
    auth_data = lti_client.get_oauth_token([LTI_SCOPES[:score]])
    line_item = self.lti_line_items.find_by!(assessment: assessment)
    score_uri = URI("#{line_item.lti_line_item_id}/scores")
    req = Net::HTTP::Post.new(score_uri)
    req['Authorization'] = "#{auth_data['token_type']} #{auth_data['access_token']}"

    if assessment.is_a?(Assignment)
      marks = get_assignment_marks(assessment)
    else
      marks = get_grade_entry_form_marks(assessment)
    end
    marks.each do |lti_user_id, mark|
      payload = {
        timestamp: Time.current.iso8601,
        scoreGiven: mark,
        scoreMaximum: assessment.max_mark.to_f,
        activityProgress: 'Completed',
        gradingProgress: 'FullyGraded',
        userId: lti_user_id
      }
      req.set_form_data(payload)
      http = Net::HTTP.new(score_uri.host, score_uri.port)
      http.request(req)
    end
  end

  # Returns a hash mapping lti_user_id to marks
  # for each released mark where the user has an lti_user_id
  def get_assignment_marks(assignment)
    marks = assignment.released_marks
    mark_data = {}
    lti_users = LtiUser.where(lti_client: lti_client)
    marks.each do |mark|
      result = mark.results.first
      group_students = mark.grouping.accepted_student_memberships
      group_students.each do |member|
        lti_user = lti_users.find_by(user: member.role.user)
        mark_data[lti_user.lti_user_id] = result.get_total_mark unless lti_user.nil?
      end
    end
    mark_data
  end

  # Returns a hash mapping lti_user_id to marks
  # for each released mark where the user has an lti_user_id
  def get_grade_entry_form_marks(grade_entry_form)
    marks = grade_entry_form.released_marks
    mark_data = {}
    lti_users = LtiUser.where(lti_client: lti_client)
    marks.each do |mark|
      lti_user = lti_users.find_by(user: mark.role.user)
      unless lti_user.nil?
        mark_data[lti_user.lti_user_id] = mark.get_total_grade
      end
    end
    mark_data
  end
end
