module CriteriaHelper

  # Load criteria based on the parsed data
  def load_criteria(criteria, assignment)
    crit_format_errors = ActiveSupport::OrderedHash.new
    num_loaded = 0
    num_format_errors = 1
    criteria.each do |criterion_yml|
      begin
        if criterion_yml[1]['type'].nil?
          RubricCriterion.create_or_update_from_yml(criterion_yml, assignment)
        elsif criterion_yml[1]['type'] == 'flexible'
          FlexibleCriterion.create_or_update_from_yml(criterion_yml, assignment)
        else
          CheckboxCriterion.create_or_update_from_yml(criterion_yml, assignment)
        end
        num_loaded += 1
      rescue RuntimeError => e
        # Collect the names of the criteria that have format errors in them.
        crit_format_errors[num_format_errors] = criterion_yml[0]
        num_format_errors = num_format_errors + 1
        flash[:error] = I18n.t('criteria.upload.syntax_error', error: "#{e}")
      end
    end

    # Communicate to the user the criteria that failed and succeeded.
    if num_loaded < criteria.length
      flash[:error] = I18n.t('criteria.upload.error') + ' ' + format_names(crit_format_errors)
    end
    if num_loaded > 0
      flash[:notice] = I18n.t('criteria.upload.success', num_loaded: num_loaded)
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
