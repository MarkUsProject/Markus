class RubricCriterion < Criterion
  self.table_name = 'rubric_criteria' # set table name correctly

  before_save :round_max_mark

  has_many :marks, as: :markable, dependent: :destroy
  accepts_nested_attributes_for :marks

  has_many :criterion_ta_associations,
           as: :criterion,
           dependent: :destroy

  has_many :tas, through: :criterion_ta_associations

  has_many :levels, -> { order(:mark) }, inverse_of: :rubric_criterion, dependent: :destroy, autosave: true
  accepts_nested_attributes_for :levels, allow_destroy: true
  before_validation :scale_marks_if_max_mark_changed
  validates_presence_of :levels

  belongs_to :assignment, foreign_key: :assessment_id, counter_cache: true

  validates_presence_of :assigned_groups_count
  validates_numericality_of :assigned_groups_count
  before_validation :update_assigned_groups_count

  has_many :test_groups, as: :criterion

  DEFAULT_MAX_MARK = 4

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

  def scale_marks_if_max_mark_changed
    return unless self.changed.include?('max_mark')
    return if self.changes['max_mark'][0].nil?
    old_max = self.changes['max_mark'][0]
    new_max = self.changes['max_mark'][1]
    scale = new_max / old_max
    self.levels.each do |level|
      # don't scale levels that the user has manually changed
      unless (level.changed.include? 'mark') || level.mark.nil?
        # use update_attribute to skip validatation in case updating level mark
        # overlaps another mark temporarily
        level.update_attribute(:mark, (level.mark * scale).round(2))
      end
    end
  end

  def mark_for(result_id)
    marks.where(result_id: result_id).first
  end

  def set_default_levels
    self.assign_attributes(levels_attributes:
      [
        { name: I18n.t('rubric_criteria.defaults.level_0'),
          description: I18n.t('rubric_criteria.defaults.description_0'), mark: 0 },
        { name: I18n.t('rubric_criteria.defaults.level_1'),
          description: I18n.t('rubric_criteria.defaults.description_1'), mark: 0.25 * self.max_mark },
        { name: I18n.t('rubric_criteria.defaults.level_2'),
          description: I18n.t('rubric_criteria.defaults.description_2'), mark: 0.5 * self.max_mark },
        { name: I18n.t('rubric_criteria.defaults.level_3'),
          description: I18n.t('rubric_criteria.defaults.description_3'), mark: 0.75 * self.max_mark },
        { name: I18n.t('rubric_criteria.defaults.level_4'),
          description: I18n.t('rubric_criteria.defaults.description_4'), mark: self.max_mark }
      ])
  end

  # Instantiate a RubricCriterion from a CSV row and attach it to the supplied
  # assignment.
  #
  # ===Params:
  #
  # row::         An array representing one CSV file row. Should be in the following
  #               format: [name, _levels_ ] where the _levels_ part contains
  #               the following information about each level in the following order:
  #               name, description, mark.
  # assignment::  The assignment to which the newly created criterion should belong.
  #
  # ===Raises:
  #
  # CsvInvalidLineError  If the row does not contain enough information, if the weight
  #                      does not evaluate to a float, or if the criterion is not
  #                      successfully saved.
  def self.create_or_update_from_csv_row(row, assignment)
    if row.empty?
      raise CsvInvalidLineError, I18n.t('upload_errors.invalid_csv_row_format')
    end
    working_row = row.clone
    name = working_row.shift

    criterion = assignment.get_criteria(:all, :rubric).find_or_create_by(name: name)

    # Only set the position if this is a new record.
    if criterion.new_record?
      criterion.position = assignment.next_criterion_position
    end

    levels_attributes = []

    # Create/update the levels. There are three entries per level.
    (working_row.length / 3).times do
      name = working_row.shift
      description = working_row.shift
      mark = Float(working_row.shift)

      if criterion.levels.exists?(name: name)
        id = criterion.levels.find_by(name: name).id
        levels_attributes.push(id: id, name: name, description: description, mark: mark)
      else
        levels_attributes.push(name: name, description: description, mark: mark)
      end
    end

    # Delete all the existing levels that were not updated
    criterion.levels.destroy(criterion.levels.where.not(id: levels_attributes.pluck(:id)))

    max_mark = levels_attributes.pluck(:mark).max

    unless criterion.update(max_mark: max_mark, levels_attributes: levels_attributes)
      raise CsvInvalidLineError, criterion.errors.full_messages
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
  #                   type: Rubric
  #                   levels:
  #                     level_name:
  #                       description: level_description
  #                       mark: level_mark
  #                     level_name:
  #                       [...]
  #                   ta_visible: true/false
  #                   peer_visible: true/false
  def self.load_from_yml(criterion_yml)
    attrs = {
      name: criterion_yml[0],
      max_mark: criterion_yml[1]['max_mark'],
      levels_attributes: []
    }
    attrs[:ta_visible] = criterion_yml[1]['ta_visible'] unless criterion_yml[1]['ta_visible'].nil?
    attrs[:peer_visible] = criterion_yml[1]['peer_visible'] unless criterion_yml[1]['peer_visible'].nil?
    criterion_yml[1]['levels'].each do |level_name, level_yml|
      attrs[:levels_attributes] << {
        name: level_name,
        description: level_yml['description'],
        mark: level_yml['mark']
      }
    end

    RubricCriterion.new(attrs)
  end

  # Returns a hash containing the information of a single rubric criterion.
  def to_yml
    levels_to_yml = { self.name => { 'type' => 'rubric',
                                     'max_mark' => self.max_mark.to_f,
                                     'levels' => {},
                                     'ta_visible' => self.ta_visible,
                                     'peer_visible' => self.peer_visible } }
    self.levels.each do |level|
      levels_to_yml[self.name]['levels'][level.name] = { 'description' => level.description,
                                                         'mark' => level.mark }
    end
    levels_to_yml
  end

  def weight
    self.max_mark
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

  def has_associated_ta?(ta)
    unless ta.ta?
      return false
    end
    !(criterion_ta_associations.where(ta_id: ta.id).first == nil)
  end
end
