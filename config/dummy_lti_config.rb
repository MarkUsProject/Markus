module LtiConfig
  # Implement LtiConfig.allowed_to_create_course? to set a filter for LTI deployments that are
  # permitted to trigger course creation for MarkUs.
  def self.allowed_to_create_course?(lti_deployment)
    lti_deployment.lms_course_name.start_with? 'csc'
  end

  def self.get_course_name(lti_deployment, course_code)
    sis_id = lti_deployment.lms_course_sourcedid
    # Perfect Scenario: (CourseCode)-(Session)-(Lecture)-(Term)
    # Example: LSM999Y1-Y-LEC0101-20259
    match = sis_id&.match(/^([a-zA-Z0-9]+)-([a-zA-Z])-LEC\d{4}-(\d+)$/)
    if match
      generated_name = "#{match[1]}#{match[2]}-#{match[3]}"
    else
      term_suffix = get_course_suffix(lti_deployment.lms_term_name)
      generated_name = "#{course_code}-#{term_suffix}"
    end
    generated_name.upcase.gsub(/[^A-Z0-9\-_]+/, '-').squeeze('-').chomp('-').delete_prefix('-')
  end

  def self.get_course_suffix(term_string)
    clean_term = term_string.to_s.strip
    return Time.current.year.to_s if clean_term.blank?
    is_scs = clean_term.downcase.include?('scs')
    # Regex: find 4 digits (2024) or 2 digits (24)
    year_match = clean_term.match(/\d{4}|\d{2}/).to_s
    month = case clean_term
            when /Fall/i then '9'
            when /Summer|Spring/i then '5'
            when /Winter/i then '1'
            end
    if !year_match.empty? && month
      year = year_match.length == 2 ? "20#{year_match}" : year_match
      suffix = "#{year}#{month}"
      return is_scs ? "SCS-#{suffix}" : suffix
    end
    clean_term.upcase.gsub(/[^A-Z0-9]+/, '-').chomp('-').delete_prefix('-')
  end
end
