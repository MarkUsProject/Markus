require 'fastercsv'
require 'csv'

class RubricCriterion < ActiveRecord::Base
  before_save :truncate_weight
  set_table_name "rubric_criteria" # set table name correctly
  belongs_to  :assignment
  has_many    :marks, :as => :markable, :dependent => :destroy
  validates_associated  :assignment, :message => 'association is not strong with an assignment'
  validates_uniqueness_of :rubric_criterion_name, :scope => :assignment_id, :message => 'is already taken'
  validates_presence_of :rubric_criterion_name, :weight, :assignment_id
  validates_numericality_of :assignment_id, :only_integer => true, :greater_than => 0, :message => "can only be whole number greater than 0"
  validates_numericality_of :weight, :message => "must be a number"
  
  
  # Just a small effort here to remove magic numbers...
  RUBRIC_LEVELS = 5
  DEFAULT_WEIGHT = 1.0
  DEFAULT_LEVELS = [
    {'name'=>'Very Poor', 'description'=>'This criterion was not satisfied.'}, 
    {'name'=>'Weak', 'description'=>'This criterion was partially satisfied.'},
    {'name'=>'Passable', 'description'=>'This criterion was satisfied.'},
    {'name'=>'Good', 'description'=>'This criterion was satisfied well.'},
    {'name'=>'Excellent', 'description'=>'This criterion was satisfied perfectly or nearly perfectly.'}
  ]
  
  def mark_for(result_id)
    return marks.find_by_result_id(result_id)
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
    csv_string = FasterCSV.generate do |csv|
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
    return csv_string
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
    if !criterion.save
      raise RuntimeError.new(criterion.errors)
    end
    return criterion
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
  def self.parse_csv(file, assignment, invalid_lines)
    nb_updates = 0
    FasterCSV.parse(file.read) do |row|
      next if FasterCSV.generate_line(row).strip.empty?
      begin
        RubricCriterion.create_or_update_from_csv_row(row, assignment)
        nb_updates += 1
      rescue RuntimeError => e
        invalid_lines << row.join(',') + ": " + e.message unless invalid_lines.nil?
      end
    end
    return nb_updates
  end
  
  def get_weight
    return self.weight
  end
  
  def truncate_weight
    factor = 10.0 ** 2
    self.weight = (self.weight * factor).floor / factor
  end
end
