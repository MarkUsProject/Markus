class CriterionTaAssociation < ApplicationRecord

  belongs_to              :ta
  validates_associated    :ta

  belongs_to              :criterion
  validates_associated    :criterion

  belongs_to              :assignment, foreign_key: :assessment_id

  before_validation       :add_assignment_reference, on: :create

  def self.from_csv(assignment, csv_data, remove_existing)
    criteria = assignment.ta_criteria.includes(:criterion_ta_associations)
    if remove_existing
      criteria.each do |criterion|
        criterion.criterion_ta_associations.destroy_all
      end
    end

    new_ta_mappings = []
    result = MarkusCsv.parse(csv_data.read) do |row|
      raise CsvInvalidLineError if row.empty?
      criterion_name, *ta_user_names = row

      criterion = criteria.find { |crit| crit.name == criterion_name }
      raise CsvInvalidLineError if criterion.nil?

      unless ta_user_names.all? { |g| Ta.exists?(user_name: g) }
        raise CsvInvalidLineError
      end

      ta_user_names.each do |user_name|
        ta_id = Ta.find_by(user_name: user_name).id
        new_ta_mappings << {
          criterion_id: criterion.id,
          ta_id: ta_id,
          assessment_id: assignment.id
        }
      end
    end

    CriterionTaAssociation.import new_ta_mappings, validate: false, on_duplicate_key_ignore: true

    Grouping.update_criteria_coverage_counts(assignment)
    Criterion.update_assigned_groups_counts(assignment)

    result
  end

  private

  def add_assignment_reference
    self.assignment = criterion.assignment
  end
end
