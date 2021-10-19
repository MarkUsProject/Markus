# Helpers for configuring the attributes of an assignment in various controllers
module AssignmentConfigHelper
  def upload_criteria(assignment, data)
    ApplicationRecord.transaction do
      assignment.criteria.destroy_all

      # Create criteria based on the parsed data.
      successes = 0
      pos = 1
      crit_format_errors = []
      data.each do |criterion_yml|
        type = criterion_yml[1]['type']
        begin
          if type&.casecmp('rubric') == 0
            criterion = RubricCriterion.load_from_yml(criterion_yml)
          elsif type&.casecmp('flexible') == 0
            criterion = FlexibleCriterion.load_from_yml(criterion_yml)
          elsif type&.casecmp('checkbox') == 0
            criterion = CheckboxCriterion.load_from_yml(criterion_yml)
          else
            raise RuntimeError
          end

          criterion.assessment_id = assignment.id
          criterion.position = pos
          criterion.save!
          pos += 1
          successes += 1
        rescue ActiveRecord::RecordInvalid # E.g., both visibility options are false.
          crit_format_errors << criterion_yml[0]
        rescue RuntimeError # An error occurred.
          crit_format_errors << criterion_yml[0]
        end
      end
      unless crit_format_errors.empty?
        flash_message(:error, "#{I18n.t('criteria.errors.invalid_format')} #{crit_format_errors.join(', ')}")
        raise ActiveRecord::Rollback
      end
      if successes > 0
        flash_message(:success,
                      I18n.t('upload_success', count: successes))
      end
    end
    reset_results_total_mark assignment.id
  end

  private

  # Resets the total mark for all results for the given assignment with id +assessment_id+.
  def reset_results_total_mark(assessment_id)
    Result.joins(submission: :grouping)
          .where('submissions.submission_version_used': true, 'groupings.assessment_id': assessment_id)
          .each do |result|
      result.update(marking_state: Result::MARKING_STATES[:incomplete])
      result.update_total_mark
    end
  end
end
