include CsvHelper
require 'iconv'

class RubricCriterion < ActiveRecord::Base
  before_save :round_weight
  after_save :update_existing_results
  set_table_name 'rubric_criteria' # set table name correctly
  belongs_to :assignment, :counter_cache => true
  has_many :marks, :as => :markable, :dependent => :destroy
  has_many :criterion_ta_associations,
           :as => :criterion,
           :dependent => :destroy
  has_many :tas, :through => :criterion_ta_associations

  validates_associated  :assignment, :on => :create
  validates_uniqueness_of :rubric_criterion_name,
                          :scope => :assignment_id
  validates_presence_of :rubric_criterion_name
  validates_presence_of :weight
  validates_presence_of :assignment_id
  validates_presence_of :assigned_groups_count
  validates_numericality_of :assignment_id,
                            :only_integer => true,
                            :greater_than => 0
  validates_numericality_of :weight
  validates_numericality_of :assigned_groups_count
  validate(:validate_total_weight, :on => :update)

  before_validation :update_assigned_groups_count

  def update_assigned_groups_count
    result = []
    criterion_ta_associations.each do |cta|
      result = result.concat(cta.ta.get_groupings_by_assignment(assignment))
    end
    self.assigned_groups_count = result.uniq.length
  end

  def validate_total_weight
    errors.add(:assignment, I18n.t('rubric_criteria.error_total')) if self.assignment.total_mark + (4 * (self.weight - self.weight_was)) <= 0
  end

  # Just a small effort here to remove magic numbers...
  RUBRIC_LEVELS = 5
  DEFAULT_WEIGHT = 1.0
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
    marks.find_by_result_id(result_id)
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
  # Wether the save operation was successful or not.
  def set_level_names(levels)
    levels.each_with_index do |level, index|
      self['level_' + index.to_s + '_name'] = level
    end
    save
  end

  # Create a CSV string from all the rubric criteria related to an assignment.
  #
  # ===Returns:
  #
  # A string. See create_or_update_from_csv_row for format reference.
  def self.create_csv(assignment)
    csv_string = CsvHelper::Csv.generate do |csv|
      assignment.rubric_criteria.each do |criterion|
        criterion_array = [criterion.rubric_criterion_name,criterion.weight]
        (0..RUBRIC_LEVELS - 1).each do |i|
          criterion_array.push(criterion['level_' + i.to_s + '_name'])
        end
        (0..RUBRIC_LEVELS - 1).each do |i|
          criterion_array.push(criterion['level_' + i.to_s + '_description'])
        end
        csv << criterion_array
      end
    end
    csv_string
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
  # RuntimeError If the row does not contains enough information, if the weight value
  #                           is zero (or doesn't evaluate to a float)
  def self.create_or_update_from_csv_row(row, assignment)
    if row.length < RUBRIC_LEVELS + 2
      raise I18n.t('criteria_csv_error.incomplete_row')
    end
    working_row = row.clone
    rubric_criterion_name = working_row.shift
    # If a RubricCriterion of the same name exits, load it up.  Otherwise,
    # create a new one.
    criterion = assignment.rubric_criteria.find_or_create_by_rubric_criterion_name(rubric_criterion_name)
    #Check that the weight is not a string.
    begin
      criterion.weight = Float(working_row.shift)
    rescue ArgumentError => e
      raise I18n.t('criteria_csv_error.weight_not_number')
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
    working_row.each_with_index do |desc, i|
      criterion['level_' + i.to_s + '_description'] = desc
    end
    unless criterion.save
      raise RuntimeError.new(criterion.errors)
    end
    criterion
  end

  # Instantiate a RubricCriterion from a YML key
  #
  # ===Params:
  #
  # key::      key corresponding to a single RubricCriterion in the
  #               following format:
  #               criterion_name:
  #                 weight: #
  #                 level_0:
  #                   name: level_name
  #                   description: level_description
  #                 level_1:
  #                   [...]
  # assignment::  The assignment to which the newly created criterion should belong.
  #
  # ===Raises:
  #
  # RuntimeError If there is not enough information, if the weight value
  #                           is zero (or doesn't evaluate to a float)
  def self.create_or_update_from_yml_key(key, assignment)
    rubric_criterion_name = key[0]
    # If a RubricCriterion of the same name exits, load it up.  Otherwise,
    # create a new one.
    criterion = assignment.rubric_criteria.find_or_create_by_rubric_criterion_name(rubric_criterion_name)
    #Check that the weight is not a string.
    begin
      criterion.weight = Float(key[1]['weight'])
    rescue ArgumentError => e
      raise I18n.t('criteria_csv_error.weight_not_number')
    rescue TypeError => e
      raise I18n.t('criteria_csv_error.weight_not_number')
    rescue NoMethodError => e
      raise I18n.t('rubric_criteria.upload.empty_error')
    end
    # Only set the position if this is a new record.
    if criterion.new_record?
      criterion.position = assignment.next_criterion_position
    end
    # next comes the level names.
    (0..RUBRIC_LEVELS-1).each do |i|
      if key[1]['level_' + i.to_s]
        criterion['level_' + i.to_s + '_name'] = key[1]['level_' + i.to_s]['name']
        criterion['level_' + i.to_s + '_description'] =
          key[1]['level_' + i.to_s]['description']
      end
    end
    unless criterion.save
      raise RuntimeError.new(criterion.errors)
    end
    criterion
  end

  # Parse a rubric criteria CSV file.
  #
  # ===Params:
  #
  # file::          A file object which will be tried for parsing.
  # assignment::    The assignment to which the new criteria should belong to.
  # invalid_lines:: An object to recieve all encountered _invalid_ lines.
  #                 Strings representing the faulty line followed by
  #                 a human readable error message are appended to the object
  #                 via the << operator.
  #
  #                 *Hint*: An array allows for an easy
  #                 access of single invalid lines.
  # ===Returns:
  #
  # The number of successfully created criteria.
  def self.parse_csv(file, assignment, invalid_lines, encoding)
    nb_updates = 0
    if encoding != nil
      file = StringIO.new(Iconv.iconv('UTF-8', encoding, file.read).join)
    end
    CsvHelper::Csv.parse(file.read) do |row|
      next if CsvHelper::Csv.generate_line(row).strip.empty?
      begin
        RubricCriterion.create_or_update_from_csv_row(row, assignment)
        nb_updates += 1
      rescue RuntimeError => e
        invalid_lines << row.join(',') + ': ' + e.message unless invalid_lines.nil?
      end
    end
    nb_updates
  end

  def get_weight
    self.weight
  end

  def round_weight
    factor = 10.0 ** 3
    self.weight = (self.weight * factor).round.to_f / factor
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
    associations = criterion_ta_associations.all(:conditions => {:ta_id => ta_array})
    ta_array.each do |ta|
      # & is the mathematical set intersection operator between two arrays
      if (ta.criterion_ta_associations & associations).size < 1
        criterion_ta_associations.create(:ta => ta, :criterion => self, :assignment => self.assignment)
      end
    end
  end


  def get_name
    rubric_criterion_name
  end

  def remove_tas(ta_array)
    ta_array = Array(ta_array)
    associations_for_criteria = criterion_ta_associations.all(:conditions => {:ta_id => ta_array})
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
    !(criterion_ta_associations.find_by_ta_id(ta.id) == nil)
  end

  def add_tas_by_user_name_array(ta_user_name_array)
    result = ta_user_name_array.map{|ta_user_name|
      Ta.find_by_user_name(ta_user_name)}.compact
    add_tas(result)
  end

  # Returns an array containing the criterion names that didn't exist
  def self.assign_tas_by_csv(csv_file_contents, assignment_id, encoding)
    failures = []
    if encoding != nil
      csv_file_contents = StringIO.new(Iconv.iconv('UTF-8', encoding, csv_file_contents.read).join)
    end
    CsvHelper::Csv.parse(csv_file_contents) do |row|
      criterion_name = row.shift # Knocks the first item from array
      criterion = RubricCriterion.find_by_assignment_id_and_rubric_criterion_name(assignment_id, criterion_name)
      if criterion.nil?
        failures.push(criterion_name)
      else
        criterion.add_tas_by_user_name_array(row) # The rest of the array
      end
    end
    return failures
  end

  # Updates results already entered with new criteria
  def update_existing_results
    self.assignment.submissions.each { |submission| submission.get_latest_result.update_total_mark }
  end

end
