require 'encoding'

# Represents a flexible criterion used to mark an assignment.
class FlexibleCriterion < Criterion
  self.table_name = 'flexible_criteria' # set table name correctly

  has_many :marks, as: :markable, dependent: :destroy

  has_many :criterion_ta_associations,
           as: :criterion,
           dependent: :destroy

  has_many :tas, through: :criterion_ta_associations

  validates_presence_of :name
  validates_uniqueness_of :name,
                          scope: :assignment_id,
                          message: I18n.t('criteria.errors.messages.name_taken')

  belongs_to :assignment, counter_cache: true
  validates_presence_of :assignment_id
  validates_associated :assignment,
                       message: I18n.t('criteria.errors.messages.assignment_association')
  validates_numericality_of :assignment_id,
                            only_integer: true,
                            greater_than: 0,
                            message: I18n.t('criteria.errors.messages.assignment_id')

  validates_presence_of :max_mark
  validates_numericality_of :max_mark,
                            greater_than: 0.0,
                            message: I18n.t('criteria.errors.messages.input_number')

  has_many :test_scripts, as: :criterion

  validate :visible?

  DEFAULT_MAX_MARK = 1

  def self.symbol
    :flexible
  end

  def update_assigned_groups_count
    result = []
    tas.each do |ta|
      result = result.concat(ta.get_groupings_by_assignment(assignment))
    end
    self.assigned_groups_count = result.uniq.length
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
  # CSVInvalidLineError  If the row does not contain enough information,
  #                      if the maximum mark is zero, nil or does not evaluate to a
  #                      float, or if the criterion is not successfully saved.
  def self.create_or_update_from_csv_row(row, assignment)
    if row.length < 2
      raise CSVInvalidLineError, I18n.t('csv.invalid_row.invalid_format')
    end
    working_row = row.clone
    name = working_row.shift
    # If a FlexibleCriterion with the same name exits, load it up.  Otherwise,
    # create a new one.
    begin
      criterion = assignment.get_criteria(:all, :flexible).find_or_create_by(name: name)
    rescue ActiveRecord::RecordNotSaved # Triggered if the assignment does not exist yet
      raise CSVInvalidLineError, I18n.t('csv.no_assignment')
    end
    # Check that max is not a string.
    begin
      criterion.max_mark = Float(working_row.shift)
    rescue ArgumentError
      raise CSVInvalidLineError, I18n.t('csv.invalid_row.invalid_format')
    end
    # Check that the maximum mark given is a valid number.
    if criterion.max_mark.nil? or criterion.max_mark.zero?
      raise CSVInvalidLineError, I18n.t('csv.invalid_row.invalid_format')
    end
    # Only set the position if this is a new record.
    if criterion.new_record?
      criterion.position = assignment.next_criterion_position
    end
    # Set description to the one cloned only if the original description is valid.
    criterion.description = working_row.shift unless row[2].nil?
    unless criterion.save
      raise CSVInvalidLineError
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
    # Check max_mark is not a string.
    begin
      criterion.max_mark = Float(criterion_yml[1]['max_mark'])
    rescue ArgumentError
      raise RuntimeError.new(I18n.t('criteria_csv_error.weight_not_number'))
    rescue TypeError
      raise RuntimeError.new(I18n.t('criteria_csv_error.weight_not_number'))
    rescue NoMethodError
      raise RuntimeError.new(I18n.t('criteria.upload.empty_error'))
    end
    # Set the description to the one given, or to an empty string if
    # a description is not given.
    criterion.description =
      criterion_yml[1]['description'].nil? ? '' : criterion_yml[1]['description']
    # Visibility options
    criterion.ta_visible = criterion_yml[1]['ta_visible'] unless criterion_yml[1]['ta_visible'].nil?
    criterion.peer_visible = criterion_yml[1]['peer_visible'] unless criterion_yml[1]['peer_visible'].nil?
    criterion
  end

  # Returns a hash containing the information of a single flexible criterion.
  def self.to_yml(criterion)
    { "#{criterion.name}" =>
      { 'type'         => 'flexible',
        'max_mark'     => criterion.max_mark.to_f,
        'description'  => criterion.description.blank? ? '' : criterion.description,
        'ta_visible'   => criterion.ta_visible,
        'peer_visible' => criterion.peer_visible }
    }
  end

  def weight
    1
  end

  def all_assigned_groups
    result = []
    tas.each do |ta|
      result = result.concat(ta.get_groupings_by_assignment(assignment))
    end
    result.uniq
  end

  def add_tas(ta_array)
    ta_array = Array(ta_array)
    associations = criterion_ta_associations.where(ta_id: ta_array)
    ta_array.each do |ta|
      if (ta.criterion_ta_associations & associations).size < 1
        criterion_ta_associations.create(ta: ta,
                                         criterion: self,
                                         assignment: self.assignment)
      end
    end
  end

  def remove_tas(ta_array)
    ta_array = Array(ta_array)
    associations_for_criteria = criterion_ta_associations.where(ta_id: ta_array)
    ta_array.each do |ta|
      # & is the mathematical set intersection operator between two arrays
      assoc_to_remove = (ta.criterion_ta_associations & associations_for_criteria)
      if assoc_to_remove.size > 0
        criterion_ta_associations.delete(assoc_to_remove)
        assoc_to_remove.first.destroy
      end
    end
  end

  def get_ta_names
    criterion_ta_associations.collect {|association| association.ta.user_name}
  end

  def has_associated_ta?(ta)
    return false unless ta.ta?
    !(criterion_ta_associations.where(ta_id: ta.id).first == nil)
  end

  def add_tas_by_user_name_array(ta_user_name_array)
    result = ta_user_name_array.map do |ta_user_name|
      Ta.find_by(user_name: ta_user_name)
    end.compact
    add_tas(result)
  end

  # Checks if the criterion is visible to either the ta or the peer reviewer.
  def visible?
    unless ta_visible || peer_visible
      errors.add(:ta_visible, I18n.t('criteria.visibility_error'))
      false
    end
    true
  end

  def set_mark_by_criterion(mark_to_change, mark_value)
    if mark_value == 'nil'
      mark_to_change.mark = nil
    else
      mark_to_change.mark = mark_value.to_f
    end
    mark_to_change.save
  end

end
