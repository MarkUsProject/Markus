module LtiConfig
  # Implement LtiConfig.allowed_to_create_course? to set a filter for LTI deployments that are
  # permitted to trigger course creation for MarkUs.
  def self.allowed_to_create_course?(lti_deployment)
    lti_deployment.lms_course_name.start_with? 'csc'
  end
end
