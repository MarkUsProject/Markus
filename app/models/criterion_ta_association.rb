# rubocop:disable Layout/LineLength, Lint/RedundantCopDisableDirective
# == Schema Information
#
# Table name: criterion_ta_associations
#
#  id            :integer          not null, primary key
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  assessment_id :bigint           not null
#  criterion_id  :integer          not null
#  ta_id         :integer          not null
#
# Indexes
#
#  index_criterion_ta_associations_on_criterion_id  (criterion_id)
#  index_criterion_ta_associations_on_ta_id         (ta_id)
#
# Foreign Keys
#
#  fk_rails_...  (assessment_id => assessments.id)
#  fk_rails_...  (criterion_id => criteria.id)
#  fk_rails_...  (ta_id => roles.id)
#
# rubocop:enable Layout/LineLength, Lint/RedundantCopDisableDirective
class CriterionTaAssociation < ApplicationRecord
  belongs_to :ta, class_name: 'Role'
  validates_associated :ta

  belongs_to :criterion
  validates_associated :criterion

  belongs_to :assignment, foreign_key: :assessment_id, inverse_of: :criterion_ta_associations

  before_validation :add_assignment_reference, on: :create

  has_one :course, through: :assignment

  validate :courses_should_match
  validate :must_be_course_staff

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
      criterion_name, *staff_user_names = row

      criterion = criteria.find { |crit| crit.name == criterion_name }
      raise CsvInvalidLineError if criterion.nil?

      course_staff = assignment.course.course_staff
      all_staff_exist = staff_user_names.all? do |staff_user_name|
        course_staff.joins(:user).exists?('users.user_name': staff_user_name)
      end
      raise CsvInvalidLineError unless all_staff_exist

      staff_user_names.each do |user_name|
        ta_id = course_staff.joins(:user).find_by('users.user_name': user_name).id
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

  def must_be_course_staff
    errors.add(:ta, :invalid) if ta && !ta.is_a?(Ta) && !ta.is_a?(Instructor)
  end

  def add_assignment_reference
    self.assignment = criterion.assignment
  end
end
