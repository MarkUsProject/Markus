module LtiConfig
  SINGLE_TERM_MONTHS = 4
  YEAR_LONG_MONTHS = 8
  # Terms a year-long course may be registered under: Winter (1) and Fall (9).
  YEAR_LONG_TERM_MONTHS = [1, 9].freeze

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
  # A single term spans 4 months, from the first day of the start month to the
  # last day of the final month (e.g. Fall: Sep 1 - Dec 31). A year-long course
  # spans Sep 1 to Apr 30 of the following year, matching the date ranges used
  # by the db:populate_course_dates rake task.
  def self.get_course_dates(lti_deployment)
    year, month, year_long = get_term_start(lti_deployment)
    return if year.nil?
    return year_long_dates(year, month) if year_long && YEAR_LONG_TERM_MONTHS.include?(month)
    dates_spanning(Date.new(year, month, 1), SINGLE_TERM_MONTHS)
  end

  # A year-long course registered under a Winter term began the previous September.
  def self.year_long_dates(year, month)
    start_year = month == 1 ? year - 1 : year
    dates_spanning(Date.new(start_year, 9, 1), YEAR_LONG_MONTHS)
  end

  # Returns [start_at, end_at] covering whole months from the first day of start_date.
  def self.dates_spanning(start_date, months)
    [start_date.beginning_of_day, (start_date + months.months - 1.day).end_of_day]
  end

  # Returns the term as [year, month, year_long], or nil. The SIS ID takes
  # precedence over the term name; it is only trusted when its term code month
  # is a real month (guards against Date.new raising Date::Error).
  def self.get_term_start(lti_deployment)
    sis_id = lti_deployment.lms_course_sourcedid
    # Session (Y) marks a year-long course: (CourseCode)-(Session)-(Lecture)-(Term)
    match = sis_id&.match(/\A[a-zA-Z0-9]+-([a-zA-Z])-LEC\d{4}-(\d{4})(\d{1,2})\z/)
    return [match[2].to_i, match[3].to_i, match[1].casecmp?('Y')] if match && match[3].to_i.between?(1, 12)
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
    [year.to_i, month, year_long_term?(clean_term)]
  end

  # A term naming both Fall and Winter covers a year-long course (e.g. '2026 Fall-Winter').
  def self.year_long_term?(term_string)
    term_string.match?(/Fall/i) && term_string.match?(/Winter/i)
  end
end
