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
    year, month = parse_term_year_month(clean_term)
    if year
      suffix = "#{year}#{month}"
      return is_scs ? "SCS-#{suffix}" : suffix
    end
    clean_term.upcase.gsub(/[^A-Z0-9]+/, '-').chomp('-').delete_prefix('-')
  end

  # Returns [start_at, end_at] for a course created from this deployment,
  # or nil when no term information can be parsed.
  # Terms span 4 months, from the first day of the start month to the last
  # day of the final month (e.g. Fall: Sep 1 - Dec 31).
  def self.get_course_dates(lti_deployment)
    year, month = get_term_start(lti_deployment)
    return if year.nil?
    start_date = Date.new(year, month, 1)
    [start_date.beginning_of_day, (start_date + 3.months).end_of_month.end_of_day]
  end

  # Returns the term start as [year, month], or nil. The SIS ID term code
  # takes precedence over the term name; a code is only trusted when its
  # month is a real month (guards against Date.new raising Date::Error).
  def self.get_term_start(lti_deployment)
    sis_id = lti_deployment.lms_course_sourcedid
    match = sis_id&.match(/\A[a-zA-Z0-9]+-[a-zA-Z]-LEC\d{4}-(\d{4})(\d{1,2})\z/)
    return [match[1].to_i, match[2].to_i] if match && match[2].to_i.between?(1, 12)
    parse_term_year_month(lti_deployment.lms_term_name)
  end

  def self.parse_term_year_month(term_string)
    clean_term = term_string.to_s.strip
    return if clean_term.blank?
    # Regex: find 4 digits (2024) or 2 digits (24)
    year_match = clean_term.match(/\d{4}|\d{2}/).to_s
    month = case clean_term
            when /Fall/i then 9
            when /Summer|Spring/i then 5
            when /Winter/i then 1
            end
    return if year_match.empty? || month.nil?
    year = year_match.length == 2 ? "20#{year_match}" : year_match
    [year.to_i, month]
  end
end
