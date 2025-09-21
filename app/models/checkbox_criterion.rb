class CheckboxCriterion < Criterion
  DEFAULT_MAX_MARK = 1

  # Instantiate a CheckboxCriterion from a CSV row and attach it to the supplied
  # assignment.
  # row: An array representing one CSV file row. Should be in the following
  #      (format = [name, max_mark, description] where description is optional)
  # assignment: The assignment to which the newly created criterion should belong.
  #
  # CsvInvalidLineError: Raised if the row does not contain enough information,
  # if the maximum mark is zero, nil or does not evaluate to a float, or if the
  # criterion is not successfully saved.
  def self.create_or_update_from_csv_row(row, assignment)
    if row.length < 2
      raise CsvInvalidLineError, I18n.t('upload_errors.invalid_csv_row_format')
    end
    working_row = row.clone
    name = working_row.shift

    # If a CheckboxCriterion with the same name exists, load it up. Otherwise,
    # create a new one.
    criterion = assignment.criteria.find_or_create_by(name: name, type: 'CheckboxCriterion')

    # Check that the maximum mark is a valid number.
    begin
      criterion.max_mark = Float(working_row.shift)
    rescue ArgumentError, TypeError
      raise CsvInvalidLineError, I18n.t('upload_errors.invalid_csv_row_format')
    end

    # Check that the maximum mark given is greater than 0.
    if criterion.max_mark.zero?
      raise CsvInvalidLineError, I18n.t('upload_errors.invalid_csv_row_format')
    end

    # Only set the position if this is a new record.
    if criterion.new_record?
      criterion.position = assignment.next_criterion_position
    end

    # Set description to the one cloned only if the original description is valid.
    criterion.description = working_row.shift unless row[2].nil?
    unless criterion.save
      raise CsvInvalidLineError
    end

    criterion
  end

  # Instantiate a CheckboxCriterion from a YML entry
  #
  # ===Params:
  #
  # criterion_yml:: Information corresponding to a single CheckboxCriterion
  #                 in the following format:
  #                 criterion_name:
  #                   type: criterion_type
  #                   max_mark: #
  #                   description: level_description
  def self.load_from_yml(criterion_yml)
    name = criterion_yml[0]
    # Create a new CheckboxCriterion
    criterion = CheckboxCriterion.new
    criterion.name = name
    criterion.max_mark = criterion_yml[1]['max_mark']

    # Set the description to the one given, or to an empty string if
    # a description is not given.
    criterion.description =
      criterion_yml[1]['description'].nil? ? '' : criterion_yml[1]['description']
    # Visibility options
    criterion.ta_visible = criterion_yml[1]['ta_visible'] unless criterion_yml[1]['ta_visible'].nil?
    criterion.peer_visible = criterion_yml[1]['peer_visible'] unless criterion_yml[1]['peer_visible'].nil?
    criterion.bonus = criterion_yml[1]['bonus'] unless criterion_yml[1]['bonus'].nil?
    criterion
  end

  # Returns a hash containing the information of a single checkbox criterion.
  def to_yml
    { self.name =>
      { 'type' => 'checkbox',
        'max_mark' => self.max_mark.to_f,
        'description' => self.description.presence || '',
        'ta_visible' => self.ta_visible,
        'peer_visible' => self.peer_visible,
        'bonus' => self.bonus } }
  end
end
