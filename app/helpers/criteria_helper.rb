module CriteriaHelper

  # Loads criteria based on the parsed data given.
  #
  # ===Raises:
  #
  # RuntimeError  If there is not enough information or if the
  #               criterion cannot be saved.
  def load_criteria(criteria, assignment)
    crit_format_errors = ActiveSupport::OrderedHash.new
    names_taken =  ActiveSupport::OrderedHash.new
    current_criteria = assignment.get_criteria
    num_loaded = 0
    num_format_errors = 0
    num_taken = 0
    criteria.each do |criterion_yml|
      assignment.get_criteria(:all, :rubric).reload
      assignment.get_criteria(:all, :flexible).reload
      assignment.get_criteria(:all, :checkbox).reload
      if current_criteria.map(&:name).include?(criterion_yml[0])
        names_taken[num_taken] = criterion_yml[0]
        num_taken += 1
      else
        begin
          if criterion_yml[1]['type'].nil?
            criterion = RubricCriterion.load_from_yml(criterion_yml, assignment)
          elsif criterion_yml[1]['type'] == 'flexible'
            criterion = FlexibleCriterion.load_from_yml(criterion_yml, assignment)
          else
            criterion = CheckboxCriterion.load_from_yml(criterion_yml, assignment)
          end
          if criterion.save
            current_criteria << criterion
            num_loaded += 1
          else
            # Collect the names of the criteria that have format errors in them.
            crit_format_errors[num_format_errors] = criterion_yml[0]
            num_format_errors += 1
            flash_message(:error, I18n.t('criteria.upload.syntax_error', error: "#{e}"))
          end
        rescue RuntimeError => e
          crit_format_errors[num_format_errors] = criterion_yml[0]
          num_format_errors += 1
          flash_message(:error, I18n.t('criteria.upload.syntax_error', error: "#{e}"))
        end
      end
    end

    # Communicate to the user the criteria that failed and succeeded.
    if num_loaded < criteria.length
      if num_format_errors > 0 and num_taken > 0
        flash_message(:error, I18n.t('criteria.upload.error.invalid_format') + ' ' +
                      format_names(crit_format_errors) + '. ' +
                      I18n.t('criteria.upload.error.names_taken') +
                      ' ' + format_names(names_taken))
      elsif num_format_errors > 0
        flash_message(:error, I18n.t('criteria.upload.error.invalid_format') + ' ' +
                      format_names(crit_format_errors))
      elsif num_taken > 0
        flash_message(:error, I18n.t('criteria.upload.error.names_taken') + ' ' +
                      format_names(names_taken))
      end
    end
    if num_loaded > 0
      flash_message(:notice, I18n.t('criteria.upload.success', num_loaded: num_loaded))
    end
  end

  # Create a String of names separated by commas from the OrderedHash
  # of criteria with format errors.
  def format_names(criteria_with_errors)
    cr_names = ''
    criteria_with_errors.each_value.with_index do |cr_name, index|
      if index == 0
        cr_names = cr_names + cr_name
      else
        cr_names = cr_names + ', ' + cr_name
      end
    end
    cr_names
  end
end
