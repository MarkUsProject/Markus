require 'mono_logger'
module LtiHelper
  # Synchronize LMS user with MarkUs users.
  # if role is not nil, attempt to create users.
  def roster_sync(lti_deployment, course, role)
    auth_data = lti_deployment.lti_client.get_oauth_token([LtiDeployment::LTI_SCOPES[:names_role]])
    names_service = lti_deployment.lti_services.find_by!(service_type: 'namesrole')
    membership_uri = URI(names_service.url)
    membership_uri.query = URI.encode_www_form(role: 'http://purl.imsglobal.org/vocab/lis/v2/membership#Learner')
    req = Net::HTTP::Get.new(membership_uri)
    res = lti_deployment.send_lti_request!(req, membership_uri, auth_data, [LtiDeployment::LTI_SCOPES[:names_role]])
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
      raise 'No user data returned from lms'
    end
    user_data.each do |lms_user|
      markus_user = EndUser.find_by(user_name: lms_user[:user_name])
      if markus_user.nil? && allowed_to?(:manage?, role, with: Admin::UserPolicy)
        EndUser.create(lms_user)
      end
      course_role = Student.find_by(user: markus_user, course: course)
      if course_role.nil? && allowed_to?(:manage?, role, with: RolePolicy)
        Student.create(user: markus_user, course: lti_deployment.course)
      end
      lti_user = LtiUser.find_or_initialize_by(user: markus_user, lti_client: lti_deployment.lti_client)
      lti_user.update!(lti_user_id: lms_user[:lti_user_id])
    end
  end

  def grade_sync(lti_deployment, assessment)
    scopes = [LtiDeployment::LTI_SCOPES[:score], LtiDeployment::LTI_SCOPES[:results]]
    lti_deployment.create_or_update_lti_assessment(assessment)
    auth_data = lti_deployment.lti_client.get_oauth_token(scopes)
    line_item = lti_deployment.lti_line_items.find_by!(assessment: assessment)
    results_uri = URI("#{line_item.lti_line_item_id}/results")
    result_req = Net::HTTP::Get.new(results_uri)
    curr_results = lti_deployment.send_lti_request!(result_req, results_uri, auth_data, scopes)
    curr_results = JSON.parse(curr_results.body)
    score_uri = URI("#{line_item.lti_line_item_id}/scores")
    req = Net::HTTP::Post.new(score_uri)

    if assessment.is_a?(Assignment)
      marks = get_assignment_marks(lti_deployment, assessment)
    else
      marks = get_grade_entry_form_marks(lti_deployment, assessment)
    end
    marks.each do |lti_user_id, mark|
      # Only send if the mark has not been previously sent to the LMS
      # or if the mark differs from the LMS mark.
      marked_by_lms = curr_results.find { |result| result['userId'] == lti_user_id }
      if marked_by_lms.nil? || marked_by_lms['resultScore'] != mark
        payload = {
          timestamp: Time.current.iso8601,
          scoreGiven: mark,
          scoreMaximum: assessment.max_mark.to_f,
          activityProgress: 'Completed',
          gradingProgress: 'FullyGraded',
          userId: lti_user_id
        }
        req.set_form_data(payload)
        lti_deployment.send_lti_request!(req, score_uri, auth_data, scopes)
      end
    end
  end

  # Returns a hash mapping lti_user_id to marks
  # for each released mark where the user has an lti_user_id
  def get_assignment_marks(lti_deployment, assignment)
    marks = assignment.released_marks
    mark_data = {}
    lti_users = LtiUser.where(lti_client: lti_deployment.lti_client)
    marks.each do |mark|
      result = mark.results.first
      group_students = mark.grouping.accepted_student_memberships
      group_students.each do |member|
        lti_user = lti_users.find_by(user: member.role.user)
        mark_data[lti_user.lti_user_id] = result.total_mark unless lti_user.nil?
      end
    end
    mark_data
  end

  # Returns a hash mapping lti_user_id to marks
  # for each released mark where the user has an lti_user_id
  def get_grade_entry_form_marks(lti_deployment, grade_entry_form)
    marks = grade_entry_form.released_marks
    mark_data = {}
    lti_users = LtiUser.where(lti_client: lti_deployment.lti_client)
    marks.each do |mark|
      lti_user = lti_users.find_by(user: mark.role.user)
      unless lti_user.nil?
        mark_data[lti_user.lti_user_id] = mark.total_grade
      end
    end
    mark_data
  end
end
