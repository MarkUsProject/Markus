module CriteriaHelper

  # Loads criteria based on the parsed data given.
  #
  # ===Raises:
  #
  # RuntimeError  If there is not enough information or if the
  #               criterion cannot be saved.
  def load_criteria(criteria, assignment)
    crit_format_errors = []
    names_taken = []
    parsed_criteria = []
    parsed_criteria_names = []
    pos = 1
    criteria.each do |criterion_yml|
      if parsed_criteria_names.include?(criterion_yml[0])
        names_taken << criterion_yml[0]
      else
        begin
          type = criterion_yml[1]['type']
          if type.nil? || type == 'rubric'
            criterion = RubricCriterion.load_from_yml(criterion_yml)
          elsif type == 'flexible'
            criterion = FlexibleCriterion.load_from_yml(criterion_yml)
          elsif type == 'checkbox'
            criterion = CheckboxCriterion.load_from_yml(criterion_yml)
          else
            raise RuntimeError
          end

          # Set assignment and position
          criterion.assignment_id = assignment.id
          criterion.position = pos
          pos += 1

          parsed_criteria << criterion
          parsed_criteria_names << criterion_yml[0]
        rescue RuntimeError
          crit_format_errors << criterion_yml[0]
        end
      end
    end

    # Save the criteria
    parsed_criteria.each do |criterion|
      unless criterion.save
        # Collect the names of the criteria that have format errors in them.
        crit_format_errors << criterion.name
      end
    end

    # Communicate to the user the criteria that failed and succeeded.
    if crit_format_errors.length > 0
      flash_message(:error,
                    I18n.t('criteria.upload.error.invalid_format') + ' ' +
                      crit_format_errors.join(', '))
    end
    if names_taken.length > 0
      flash_message(:error,
                    I18n.t('criteria.upload.error.names_taken') + ' ' +
                      names_taken.join(', '))
    end

    num_loaded = assignment.get_criteria.length
    if num_loaded > 0
      flash_message(:success,
                    I18n.t('criteria.upload.success', num_loaded: num_loaded))
    end
  end
end
