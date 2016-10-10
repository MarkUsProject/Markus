require 'encoding'

class RubricCriterion < Criterion
  self.table_name = 'rubric_criteria' # set table name correctly

  validates_presence_of :max_mark
  validates_numericality_of :max_mark
  before_save :round_max_mark

  after_save :update_existing_results

  has_many :marks, as: :markable, dependent: :destroy

  has_many :criterion_ta_associations,
           as: :criterion,
           dependent: :destroy

  has_many :tas, through: :criterion_ta_associations

  belongs_to :assignment, counter_cache: true
  validates_associated :assignment, on: :create
  validates_presence_of :assignment_id
  validates_numericality_of :assignment_id,
                            only_integer: true,
                            greater_than: 0

  validates_presence_of :max_mark
  validates_numericality_of :max_mark,
                            message: I18n.t('criteria.errors.messages.input_number'),
                            greater_than: 0.0

  validates_presence_of :name
  validates_uniqueness_of :name,
                          scope: :assignment_id,
                          message: I18n.t('criteria.errors.messages.name_taken')

  validates_presence_of :assigned_groups_count
  validates_numericality_of :assigned_groups_count
  before_validation :update_assigned_groups_count

  has_many :test_scripts, as: :criterion

  validate :visible?

  def self.symbol
    :rubric
  end

  def update_assigned_groups_count
    result = []
    criterion_ta_associations.each do |cta|
      result = result.concat(cta.ta.get_groupings_by_assignment(assignment))
    end
    self.assigned_groups_count = result.uniq.length
  end

  # Just a small effort here to remove magic numbers...
  RUBRIC_LEVELS = 5
  DEFAULT_MAX_MARK = 4
  MAX_LEVEL = RUBRIC_LEVELS - 1
  DEFAULT_LEVELS = [
    {'name' => I18n.t('rubric_criteria.defaults.level_0'),
     'description' => I18n.t('rubric_criteria.defaults.description_0')},
    {'name' => I18n.t('rubric_criteria.defaults.level_1'),
     'description' => I18n.t('rubric_criteria.defaults.description_1')},
    {'name' => I18n.t('rubric_criteria.defaults.level_2'),
     'description' => I18n.t('rubric_criteria.defaults.description_2')},
    {'name' => I18n.t('rubric_criteria.defaults.level_3'),
     'description' => I18n.t('rubric_criteria.defaults.description_3')},
    {'name' => I18n.t('rubric_criteria.defaults.level_4'),
     'description' => I18n.t('rubric_criteria.defaults.description_4')}
  ]

  def mark_for(result_id)
    marks.where(result_id: result_id).first
  end

  def set_default_levels
    DEFAULT_LEVELS.each_with_index do |level, index|
      self['level_' + index.to_s + '_name'] = level['name']
      self['level_' + index.to_s + '_description'] = level['description']
    end
  end

  # Set all the level names at once and saves the object.
  #
  # ===Params:
  #
  # levels::  An array containing every level name. A rubric criterion contains
  #           RUBRIC_LEVELS levels. If the array is smaller, only the first levels
  #           are set. If the array is bigger, higher indexes are ignored.
  #
  # ===Returns:
  #
  # Whether the save operation was successful or not.
  def set_level_names(levels)
    levels.each_with_index do |level, index|
      self['level_' + index.to_s + '_name'] = level
    end
    save
  end

  # Instantiate a RubricCriterion from a CSV row and attach it to the supplied
  # assignment.
  #
  # ===Params:
  #
  # row::         An array representing one CSV file row. Should be in the following
  #               format: [name, weight, _names_, _descriptions_] where the _names_ part
  #               must contain RUBRIC_LEVELS elements representing the name of each
  #               level and the _descriptions_ part (optional) can contain up to
  #               RUBRIC_LEVELS description (one for each level).
  # assignment::  The assignment to which the newly created criterion should belong.
  #
  # ===Raises:
  #
  # CSVInvalidLineError  If the row does not contain enough information, if the weight
  #                      does not evaluate to a float, or if the criterion is not
  #                      successfully saved.
  def self.create_or_update_from_csv_row(row, assignment)
    if row.length < RUBRIC_LEVELS + 2
      raise CSVInvalidLineError, I18n.t('csv.invalid_row.invalid_format')
    end
    working_row = row.clone
    name = working_row.shift
    # If a RubricCriterion of the same name exits, load it up.  Otherwise,
    # create a new one.
    begin
    criterion = assignment.get_criteria(:all, :rubric).find_or_create_by(name: name)
    rescue ActiveRecord::RecordNotSaved # Triggered if the assignment does not exist yet
      raise CSVInvalidLineError, I18n.t('csv.no_assignment')
    end
    # Check that the weight is not a string, so that the appropriate max mark can be calculated.
    begin
      criterion.max_mark = Float(working_row.shift) * MAX_LEVEL
    rescue ArgumentError
      raise CSVInvalidLineError, I18n.t('csv.invalid_row.invalid_format')
    end
    # Only set the position if this is a new record.
    if criterion.new_record?
      criterion.position = assignment.next_criterion_position
    end
    # next comes the level names.
    (0..RUBRIC_LEVELS-1).each do |i|
      criterion['level_' + i.to_s + '_name'] = working_row.shift
    end
    # the rest of the values are level descriptions.
    (0..RUBRIC_LEVELS-1).each do |i|
      criterion['level_' + i.to_s + '_description'] = working_row.shift
    end
    unless criterion.save
      raise CSVInvalidLineError
    end
    criterion
  end

  # Instantiate a RubricCriterion from a YML entry
  #
  # ===Params:
  #
  # criterion_yml:: Information corresponding to a single RubricCriterion
  #                 in the following format:
  #                 criterion_name:
  #                   weight: #
  #                   level_0:
  #                     name: level_name
  #                     description: level_description
  #                   level_1:
  #                     [...]
  def self.load_from_yml(criterion_yml)
    name = criterion_yml[0]
    # Create a new RubricCriterion
    criterion = RubricCriterion.new
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
    # Next comes the level names.
    (0..RUBRIC_LEVELS-1).each do |i|
      if criterion_yml[1]['level_' + i.to_s]
        criterion['level_' + i.to_s + '_name'] =
          criterion_yml[1]['level_' + i.to_s]['name']
        criterion['level_' + i.to_s + '_description'] =
          criterion_yml[1]['level_' + i.to_s]['description']
      end
    end
    # Visibility options
    criterion.ta_visible = criterion_yml[1]['ta_visible'] unless criterion_yml[1]['ta_visible'].nil?
    criterion.peer_visible = criterion_yml[1]['peer_visible'] unless criterion_yml[1]['peer_visible'].nil?
    criterion
  end

  # Returns a hash containing the information of a single rubric criterion.
  def self.to_yml(criterion)
    { "#{criterion.name}" =>
      { 'max_mark'     => criterion.max_mark.to_f,
        'level_0'      => { 'name'        => criterion.level_0_name,
                            'description' => criterion.level_0_description },
        'level_1'      => { 'name'        => criterion.level_1_name,
                            'description' => criterion.level_1_description },
        'level_2'      => { 'name'        => criterion.level_2_name,
                            'description' => criterion.level_2_description },
        'level_3'      => { 'name'        => criterion.level_3_name,
                            'description' => criterion.level_3_description },
        'level_4'      => { 'name'        => criterion.level_4_name,
                            'description' => criterion.level_4_description },
        'ta_visible'   => criterion.ta_visible,
        'peer_visible' => criterion.peer_visible }
    }
  end

  def weight
    max_mark / MAX_LEVEL
  end

  def round_max_mark
    # (this was being done in a weird way, leaving the original in case there are problems)
    # factor = 10.0 ** 3
    # self.max_mark = (max_mark * factor).round.to_f / factor
    self.max_mark = self.max_mark.round(3)
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
    associations = criterion_ta_associations.where(ta_id: ta_array).to_a
    ta_array.each do |ta|
      # & is the mathematical set intersection operator between two arrays
      if (ta.criterion_ta_associations & associations).size < 1
        criterion_ta_associations.create(ta: ta, criterion: self, assignment: self.assignment)
      end
    end
  end

  def remove_tas(ta_array)
    ta_array = Array(ta_array)
    associations_for_criteria = criterion_ta_associations.where(
      ta_id: ta_array).to_a
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
    unless ta.ta?
      return false
    end
    !(criterion_ta_associations.where(ta_id: ta.id).first == nil)
  end

  def add_tas_by_user_name_array(ta_user_name_array)
    result = ta_user_name_array.map do |ta_user_name|
      Ta.find_by(user_name: ta_user_name)
    end.compact
    add_tas(result)
  end

  # Updates results already entered with new criteria
  def update_existing_results
    self.assignment.submissions.each { |submission| submission.get_latest_result.update_total_mark }
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
