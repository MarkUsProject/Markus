# Helpers for handling criteria in various controllers
module CriteriaHelper
  # Configures +assignment+ with the uploaded criteria +data+
  # Returns the number of successful criteria uploaded
  def upload_criteria_from_yaml(assignment, data)
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
      rescue ActiveRecord::RecordInvalid, RuntimeError # E.g., both visibility options are false.
        crit_format_errors << criterion_yml[0]
      end
    end
    unless crit_format_errors.empty?
      raise "#{I18n.t('criteria.errors.invalid_format')} #{crit_format_errors.join(', ')}"
    end
    reset_results_total_mark(assignment.id)
    successes
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
