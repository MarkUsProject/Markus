require 'net/http'
module LtiHelper
  # Synchronize LMS user with MarkUs users.
  # if role is not nil, attempt to create users
  # based on the values of can_create_users and
  # can_create_roles.
  def roster_sync(lti_deployment, role_types, can_create_users: false, can_create_roles: false)
    error = false
    course = lti_deployment.course
    auth_data = lti_deployment.lti_client.get_oauth_token([LtiDeployment::LTI_SCOPES[:names_role]])
    names_service = lti_deployment.lti_services.find_by!(service_type: 'namesrole')
    membership_uri = URI(names_service.url)
    if lti_deployment.resource_link_id
      query = begin
        URI.decode_www_form(String(membership_uri.query))
      rescue StandardError
        []
      end
      query << ['rlid', lti_deployment.resource_link_id]
      membership_uri.query = URI.encode_www_form(query)
    end
    member_info, follow = get_member_data(lti_deployment, membership_uri, auth_data)
    while follow != false
      additional_data, follow = get_member_data(lti_deployment, follow, auth_data)
      member_info.concat(additional_data)
    end
    user_data = member_info.filter_map do |user|
      unless user['status'] == 'Inactive' || user['roles'].include?(LtiDeployment::LTI_ROLES['test_user']) ||
        role_types.none? { |role| user['roles'].include?(role) }
        custom_claims = user.dig('message', 0, LtiDeployment::LTI_CLAIMS[:custom])
        student_number = custom_claims.present? ? custom_claims['student_number'] : nil
        id_number_value = if student_number.blank? || student_number == '$Canvas.user.sisIntegrationId'
                            nil
                          else
                            student_number
                          end
        { user_name: user['lis_person_sourcedid'].nil? ? user['name'].delete(' ') : user['lis_person_sourcedid'],
          first_name: user['given_name'],
          last_name: user['family_name'],
          display_name: user['name'],
          email: user['email'],
          id_number: id_number_value,
          lti_user_id: user['user_id'],
          roles: user['roles'] }
      end
    end
    if user_data.empty?
      raise I18n.t('lti.no_users')
    end
    user_data.each do |lms_user|
      markus_user = EndUser.find_by(user_name: lms_user[:user_name])
      if markus_user.nil? && can_create_users
        markus_user = EndUser.create(lms_user.except(:lti_user_id, :roles))
        if markus_user.nil?
          error = true
          next
        end
      elsif markus_user.nil? && !can_create_users
        error = true
        next
      end
      course_role = Role.find_by(user: markus_user, course: course)
      if course_role.nil? && can_create_roles
        if lms_user[:roles].include?(LtiDeployment::LTI_ROLES[:ta])
          course_role = Ta.create!(user: markus_user, course: lti_deployment.course)
        elsif lms_user[:roles].include?(LtiDeployment::LTI_ROLES[:instructor])
          course_role = Instructor.create!(user: markus_user, course: lti_deployment.course)
        elsif lms_user[:roles].include?(LtiDeployment::LTI_ROLES[:learner])
          course_role = Student.create!(user: markus_user, course: lti_deployment.course)
        end
      end
      next if course_role.nil?
      lti_user = LtiUser.find_or_initialize_by(user: markus_user, lti_client: lti_deployment.lti_client)
      lti_user.update!(lti_user_id: lms_user[:lti_user_id])
    end
    error
  end

  def grade_sync(lti_deployment, assessment)
    scopes = [LtiDeployment::LTI_SCOPES[:score], LtiDeployment::LTI_SCOPES[:results]]
    create_or_update_lti_assessment(lti_deployment, assessment)
    auth_data = lti_deployment.lti_client.get_oauth_token(scopes)
    line_item = lti_deployment.lti_line_items.find_by!(assessment: assessment)
    curr_results = get_current_results(line_item, auth_data, scopes)
    score_uri = URI("#{line_item.lti_line_item_id}/scores")
    req = Net::HTTP::Post.new(score_uri)

    if assessment.is_a?(Assignment)
      marks = get_assignment_marks(lti_deployment, assessment)
    else
      marks = get_grade_entry_form_marks(lti_deployment, assessment)
    end
    if marks.empty?
      raise I18n.t('lti.no_grades')
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
    released_results = assignment.released_marks
                                 .joins(grouping: [{ accepted_student_memberships: { role: { user: :lti_users } } }])
                                 .where('lti_users.lti_client': lti_deployment.lti_client)
                                 .pluck('lti_users.lti_user_id', 'results.id')
    result_ids = released_results.pluck(1)
    grades = Result.get_total_marks(result_ids)
    released_results.map do |result|
      next if result[0].nil?
      [result[0], grades[result[1]]]
    end.to_h
  end

  # Returns a hash mapping lti_user_id to marks
  # for each released mark where the user has an lti_user_id
  def get_grade_entry_form_marks(lti_deployment, grade_entry_form)
    student_data = grade_entry_form.released_marks
                                   .joins(role: { user: :lti_users })
                                   .where('lti_users.lti_client': lti_deployment.lti_client)
                                   .pluck('lti_users.lti_user_id', 'grade_entry_students.id')

    ges_ids = student_data.pluck(1)
    grades = GradeEntryStudent.get_total_grades(ges_ids)
    student_data.map do |student|
      next if student[0].nil?
      [student[0], grades[student[1]]]
    end.to_h
  end

  # Creates or updates an assignment in the LMS gradebook for a given assessment.
  def create_or_update_lti_assessment(lti_deployment, assessment)
    payload = {
      label: assessment.description,
      resourceId: assessment.short_identifier,
      scoreMaximum: assessment.max_mark.to_f
    }
    auth_data = lti_deployment.lti_client.get_oauth_token([LtiDeployment::LTI_SCOPES[:ags_lineitem]])
    lineitem_service = lti_deployment.lti_services.find_by!(service_type: 'agslineitem')
    lineitem_uri = URI(lineitem_service.url)
    line_item = lti_deployment.lti_line_items.find_or_initialize_by(assessment: assessment)
    if line_item.lti_line_item_id?
      req = Net::HTTP::Put.new(line_item.lti_line_item_id)
    else
      req = Net::HTTP::Post.new(lineitem_uri)
    end
    req.set_form_data(payload)
    res = lti_deployment.send_lti_request!(req, lineitem_uri, auth_data, [LtiDeployment::LTI_SCOPES[:ags_lineitem]])
    line_item_data = JSON.parse(res.body)
    line_item.update!(lti_line_item_id: line_item_data['id'])
  end

  def get_current_results(lti_line_item, auth_data, scopes)
    results_uri = URI("#{lti_line_item.lti_line_item_id}/results")
    result_req = Net::HTTP::Get.new(results_uri)
    curr_results = lti_line_item.lti_deployment.send_lti_request!(result_req, results_uri, auth_data, scopes)
    JSON.parse(curr_results.body)
  end

  def get_member_data(lti_deployment, url, auth_data)
    req = Net::HTTP::Get.new(url)
    res = lti_deployment.send_lti_request!(req, url, auth_data, [LtiDeployment::LTI_SCOPES[:names_role]])
    member_info = JSON.parse(res.body)
    links = res['link']
    unless links
      return [member_info['members'], false]
    end
    split_links = links.split(',')
    split_next = split_links.find { |link| link.include?('next') }
    next_link = split_next&.split(';')&.[](0)&.tr('<>', '')&.strip
    next_uri = URI(next_link) if next_link
    follow_link = false
    follow_link = next_uri if next_uri
    [member_info['members'], follow_link]
  end
end
