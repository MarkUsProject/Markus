class Ta < User

  CSV_UPLOAD_ORDER = USER_TA_CSV_UPLOAD_ORDER
  SESSION_TIMEOUT = USER_TA_SESSION_TIMEOUT

  has_many :criterion_ta_associations, dependent: :delete_all

  has_many :grade_entry_student_tas, dependent: :delete_all
  has_many :grade_entry_students, through: :grade_entry_student_tas, dependent: :delete_all

  BLANK_MARK = ''

  def get_criterion_associations_by_assignment(assignment)
    if assignment.assignment_properties.assign_graders_to_criteria
      criterion_ta_associations.includes(:assignment, :criterion).select do |association|
        association.assignment == assignment
      end
    else
      []
    end
  end

  def get_criterion_associations_count_by_assignment(assignment)
    assignment.criterion_ta_associations
              .where(ta_id: id)
              .count
  end

  def get_membership_count_by_assignment(assignment)
    memberships.where(groupings: { assessment_id: assignment.id })
               .includes(:grouping)
               .count
  end

  def get_groupings_by_assignment(assignment)
    groupings.where(assessment_id: assignment.id)
             .includes(:students, :tas, :group, :assignment)
  end

  def get_membership_count_by_grade_entry_form(grade_entry_form)
    grade_entry_students.where('assessment_id = ?', grade_entry_form.id)
                        .includes(:grade_entry_form)
                        .count
  end

  # Determine the total mark for a particular student, as a percentage
  def calculate_total_percent(result, out_of)
    total = result.total_mark

    percent = BLANK_MARK

    # Check for NA mark or division by 0
    unless total.nil? || out_of == 0
      percent = (total / out_of) * 100
    end
    percent
  end

  # An array of all the grades for an assignment
  def percentage_grades_array(assignment)
    grades = Array.new()
    out_of = assignment.max_mark
    assignment.groupings.includes(:current_result).joins(:tas)
      .where(memberships: { user_id: id }).find_each do |grouping|
      result = grouping.current_result
      unless result.nil? || result.total_mark.nil? || result.marking_state != Result::MARKING_STATES[:complete]
        percent = calculate_total_percent(result, out_of)
        unless percent == BLANK_MARK
          grades.push(percent)
        end
      end
    end

    return grades
  end

  # Returns grade distribution for a grade entry item for each student
  def grade_distribution_array(assignment, intervals = 20)
    data = percentage_grades_array(assignment)
    data.extend(Histogram)
    histogram = data.histogram(intervals, :min => 1, :max => 100, :bin_boundary => :min, :bin_width => 100 / intervals)
    distribution = histogram.fetch(1)
    distribution[0] = distribution.first + data.count{ |x| x < 1 }
    distribution[-1] = distribution.last + data.count{ |x| x > 100 }

    return distribution
  end
end
