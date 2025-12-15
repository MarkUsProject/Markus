# Represents a flexible criterion used to mark an assignment.
class FlexibleCriterion < Criterion
  has_many :annotation_categories

  before_destroy :reassign_annotation_category, prepend: true

  DEFAULT_MAX_MARK = 1

  def reassign_annotation_category
    self.annotation_categories.each do |category|
      category.update!(flexible_criterion_id: nil)
    end
  end

  # Instantiate a FlexibleCriterion from a CSV row and attach it to the supplied
  # assignment.
  #
  # ===Params:
  #
  # row::         An array representing one CSV file row. Should be in the following
  #               format: [name, max_mark, description] where description is optional.
  # assignment::  The assignment to which the newly created criterion should belong.
  #
  # ===Raises:
  #
  # CsvInvalidLineError  If the row does not contain enough information,
  #                      if the maximum mark is zero, nil or does not evaluate to a
  #                      float, or if the criterion is not successfully saved.
  def self.create_or_update_from_csv_row(row, assignment)
    if row.length < 2
      raise CsvInvalidLineError, I18n.t('upload_errors.invalid_csv_row_format')
    end
    working_row = row.clone
    name = working_row.shift
    # If a FlexibleCriterion with the same name exits, load it up.  Otherwise,
    # create a new one.
    criterion = assignment.criteria.find_or_create_by(name: name, type: 'FlexibleCriterion')
    # Check that maximum mark is a valid number
    begin
      criterion.max_mark = Float(working_row.shift)
    rescue ArgumentError, TypeError
      raise CsvInvalidLineError, I18n.t('upload_errors.invalid_csv_row_format')
    end
    # Check that the maximum mark given is zero.
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

  # Instantiate a FlexibleCriterion from a YML entry
  #
  # ===Params:
  #
  # criterion_yml:: Information corresponding to a single FlexibleCriterion
  #                 in the following format:
  #                 criterion_name:
  #                   type: criterion_type
  #                   max_mark: #
  #                   description: level_description
  def self.load_from_yml(criterion_yml)
    name = criterion_yml[0]
    # Create a new RubricCriterion
    criterion = FlexibleCriterion.new
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

  # Returns a hash containing the information of a single flexible criterion.
  def to_yml
    { self.name =>
      { 'type' => 'flexible',
        'max_mark' => self.max_mark.to_f,
        'description' => self.description.presence || '',
        'ta_visible' => self.ta_visible,
        'peer_visible' => self.peer_visible,
        'bonus' => self.bonus } }
  end

  def scale_marks
    super
    return if self.annotation_categories.nil?
    annotation_categories = self.annotation_categories.includes(:annotation_texts)
    annotation_categories.each do |category|
      category.annotation_texts.each do |text|
        text.scale_deduction(previous_changes['max_mark'][1] / previous_changes['max_mark'][0])
      end
    end
  end
end
