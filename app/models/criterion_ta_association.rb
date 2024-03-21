class CriterionTaAssociation < ApplicationRecord
  belongs_to :ta
  validates_associated :ta

  belongs_to :criterion
  validates_associated :criterion

  belongs_to :assignment, foreign_key: :assessment_id, inverse_of: :criterion_ta_associations

  before_validation :add_assignment_reference, on: :create

  has_one :course, through: :assignment

  validate :courses_should_match

  def self.from_csv(assignment, csv_data, remove_existing)
    criteria = assignment.ta_criteria.includes(:criterion_ta_associations)
    if remove_existing
      criteria.each do |criterion|
        criterion.criterion_ta_associations.destroy_all
      end
    end

    new_ta_mappings = []
    result = MarkusCsv.parse(csv_data) do |row|
      raise CsvInvalidLineError if row.empty?
      criterion_name, *ta_user_names = row

      criterion = criteria.find { |crit| crit.name == criterion_name }
      raise CsvInvalidLineError if criterion.nil?

      course_tas = assignment.course.tas
      unless ta_user_names.all? { |g| course_tas.joins(:user).exists?('users.user_name': g) }
        raise CsvInvalidLineError
      end

      ta_user_names.each do |user_name|
        ta_id = course_tas.joins(:user).find_by('users.user_name': user_name).id
        new_ta_mappings << {
          criterion_id: criterion.id,
          ta_id: ta_id,
          assessment_id: assignment.id
        }
      end
    end

    CriterionTaAssociation.insert_all(new_ta_mappings) unless new_ta_mappings.empty?

    Grouping.update_criteria_coverage_counts(assignment)
    Criterion.update_assigned_groups_counts(assignment)

    result
  end

  private

  def add_assignment_reference
    self.assignment = criterion.assignment
  end
end
