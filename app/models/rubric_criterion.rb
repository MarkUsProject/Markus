class RubricCriterion < Criterion
  self.table_name = 'rubric_criteria' # set table name correctly

  before_save :round_max_mark

  has_many :marks, as: :markable, dependent: :destroy
  accepts_nested_attributes_for :marks

  has_many :criterion_ta_associations,
           as: :criterion,
           dependent: :destroy

  has_many :tas, through: :criterion_ta_associations

  has_many :levels, -> { order(:mark) }

  belongs_to :assignment, counter_cache: true

  validates_presence_of :assigned_groups_count
  validates_numericality_of :assigned_groups_count
  before_validation :update_assigned_groups_count

  has_many :test_groups, as: :criterion

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

  RUBRIC_LEVELS = 5
  DEFAULT_MAX_MARK = 4
  MAX_LEVEL = RUBRIC_LEVELS - 1

  def mark_for(result_id)
    marks.where(result_id: result_id).first
  end

  def set_default_levels
    default_levels = [
      { 'name' => I18n.t('rubric_criteria.defaults.level_0'),
        'description' => I18n.t('rubric_criteria.defaults.description_0') },
      { 'name' => I18n.t('rubric_criteria.defaults.level_1'),
        'description' => I18n.t('rubric_criteria.defaults.description_1') },
      { 'name' => I18n.t('rubric_criteria.defaults.level_2'),
        'description' => I18n.t('rubric_criteria.defaults.description_2') },
      { 'name' => I18n.t('rubric_criteria.defaults.level_3'),
        'description' => I18n.t('rubric_criteria.defaults.description_3') },
      { 'name' => I18n.t('rubric_criteria.defaults.level_4'),
        'description' => I18n.t('rubric_criteria.defaults.description_4') }
    ]
    default_levels.each_with_index do |level, index|
      # creates a new level and saves it to database
      self.levels.create(name: level['name'], number: index,
                         description: level['description'], mark: index)
    end
  end

  # Instantiate a RubricCriterion from a CSV row and attach it to the supplied
  # assignment.
  #
  # ===Params:
  #
  # row::         An array representing one CSV file row. Should be in the following
  #               format: [name, weight, _levels_ ] where the _levels part contains
  #               the following information about each level in the following order:
  #               name, number, description, mark.
  # assignment::  The assignment to which the newly created criterion should belong.
  #
  # ===Raises:
  #
  # CsvInvalidLineError  If the row does not contain enough information, if the weight
  #                      does not evaluate to a float, or if the criterion is not
  #                      successfully saved.
  def self.create_or_update_from_csv_row(row, assignment)
    if row.length < RUBRIC_LEVELS + 2
      raise CsvInvalidLineError, I18n.t('upload_errors.invalid_csv_row_format')
    end

    working_row = row.clone
    name = working_row.shift
    # If a RubricCriterion of the same name exits, load it up.  Otherwise,
    # create a new one.
    criterion = assignment.get_criteria(:all, :rubric).find_or_create_by(name: name)
    # Check that the weight is not a string, so that the appropriate max mark can be calculated.
    begin
      criterion.max_mark = Float(working_row.shift) * MAX_LEVEL
    rescue ArgumentError
      raise CsvInvalidLineError, I18n.t('upload_errors.invalid_csv_row_format')
    end
    # Only set the position if this is a new record.
    if criterion.new_record?
      criterion.position = assignment.next_criterion_position
    end

    # there are 5 fields for each level
    num_levels = working_row.length / 5

    # create/update the levels
    (0..num_levels).each do
      name = working_row.shift
      number = working_row.shift
      description = working_row.shift
      mark = working_row.shift
      # if level name exists we will update the level
      if criterion.levels.exists?(name: name)
        level = criterion.levels.find_by(name: name)
        criterion.levels.upsert(id: level.id, rubric_criterion_id: level.rubric_criterion_id, name: name,
                                number: number, description: description, mark: level.mark,
                                created_at: level.created_at, updated_at: level.updated_at)
      # Otherwise, we create a new level
      else
        criterion.levels.create(name: name, number: number, description: description, mark: mark)
      end
      unless criterion.save
        raise CsvInvalidLineError
      end
    end
  end

  # Instantiate a RubricCriterion from a YML entry
  #
  # ===Params:
  #
  # criterion_yml:: Information corresponding to a single RubricCriterion
  #                 in the following format:
  #                 criterion_name:
  #                   max_mark: #
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
    criterion.max_mark = criterion_yml[1]['max_mark']

    # Next comes the level names.
    (0..RUBRIC_LEVELS - 1).each do |i|
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
  def to_yml
    { self.name =>
      { 'type' => 'rubric',
        'max_mark' => self.max_mark.to_f,
        'level_0' => { 'name' => self.level_0_name,
                       'description' => self.level_0_description },
        'level_1' => { 'name' => self.level_1_name,
                       'description' => self.level_1_description },
        'level_2' => { 'name' => self.level_2_name,
                       'description' => self.level_2_description },
        'level_3' => { 'name' => self.level_3_name,
                       'description' => self.level_3_description },
        'level_4' => { 'name' => self.level_4_name,
                       'description' => self.level_4_description },
        'ta_visible' => self.ta_visible,
        'peer_visible' => self.peer_visible } }
  end

  def weight
    max_mark / MAX_LEVEL
  end

  def round_max_mark
    # (this was being done in a weird way, leaving the original in case there are problems)
    # factor = 10.0 ** 3
    # self.max_mark = (max_mark * factor).round.to_f / factor
    self.max_mark = self.max_mark.round(1)
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
      unless assoc_to_remove.empty?
        criterion_ta_associations.delete(assoc_to_remove)
        assoc_to_remove.first.destroy
      end
    end
  end

  def get_ta_names
    criterion_ta_associations.collect { |association| association.ta.user_name }
  end

  def has_associated_ta?(ta)
    unless ta.ta?
      return false
    end

    !(criterion_ta_associations.where(ta_id: ta.id).first == nil)
  end
end
