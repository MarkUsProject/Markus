include CsvHelper
require 'iconv'
# Represents a flexible criterion used to mark an assignment that
# has the marking_scheme_type attribute set to 'flexible'.
class FlexibleCriterion < ActiveRecord::Base

  set_table_name 'flexible_criteria' # set table name correctly
  belongs_to :assignment, :counter_cache => true

  has_many :marks, :as => :markable, :dependent => :destroy

  has_many :criterion_ta_associations,
           :as => :criterion,
           :dependent => :destroy

  has_many :tas, :through => :criterion_ta_associations

  validates_associated :assignment,
                  :message => 'association is not strong with an assignment'
  validates_uniqueness_of :flexible_criterion_name,
                          :scope => :assignment_id,
                          :message => 'is already taken'
  validates_presence_of :flexible_criterion_name, :assignment_id, :max
  validates_numericality_of :assignment_id,
                        :only_integer => true,
                        :greater_than => 0,
                        :message => 'can only be whole number greater than 0'
  validates_numericality_of :max,
                            :message => 'must be a number greater than 0.0',
                            :greater_than => 0.0

#  before_save :update_assigned_groups_count

  DEFAULT_MAX = 1

  def update_assigned_groups_count
    result = []
    tas.each do |ta|
      result = result.concat(ta.get_groupings_by_assignment(assignment))
    end
    self.assigned_groups_count = result.uniq.length
  end

  # Creates a CSV string from all the flexible criteria related to an assignment.
  #
  # ===Returns:
  #
  # A string. see new_from_csv_row for format reference.
  def self.create_csv(assignment)
    csv_string = CsvHelper::Csv.generate do |csv|
      # TODO temporary until Assignment gets its criteria method
      criteria = FlexibleCriterion.find_all_by_assignment_id(assignment.id, :order => :position)
      criteria.each do |c|
        criterion_array = [c.flexible_criterion_name, c.max, c.description]
        csv << criterion_array
      end
    end
    return csv_string
  end

  # Instantiate a FlexibleCriterion from a CSV row and attach it to the supplied
  # assignment.
  #
  # ===Params:
  #
  # row::         An array representing one CSV file row. Should be in the following
  #               format: [name, max, description] where description is optional.
  # assignment::  The assignment to which the newly created criterion should belong.
  #
  # ===Raises:
  #
  # CSV::IllegalFormatError:: DEPRECATED in Ruby 1.8.7
  #                           REMOVED in Ruby 1.9.2
  #
  # CSV::MalformedCSVError::  If the row does not contains enough information, if the max value
  #                           is zero (or doesn't evaluate to a float) or if the
  #                           supplied name is not unique.
  def self.new_from_csv_row(row, assignment)
    if row.length < 2
      if RUBY_VERSION > '1.9'
        raise CSV::MalformedCSVError.new(I18n.t('criteria_csv_error.incomplete_row'))
      else
        raise CSV::IllegalFormatError.new(I18n.t('criteria_csv_error.incomplete_row'))
      end
    end
    criterion = FlexibleCriterion.new
    criterion.assignment = assignment
    criterion.flexible_criterion_name = row[0]
    # assert that no other criterion uses the same name for the same assignment.
    if FlexibleCriterion.find_all_by_assignment_id_and_flexible_criterion_name(assignment.id, criterion.flexible_criterion_name).size != 0
      if RUBY_VERSION > '1.9'
        raise CSV::MalformedCSVError.new(I18n.t('criteria_csv_error.name_not_unique'))
      else
        raise CSV::IllegalFormatError.new(I18n.t('criteria_csv_error.name_not_unique'))
      end
    end
    criterion.max = row[1]
    if criterion.max == 0
      if RUBY_VERSION > '1.9'
        raise CSV::MalformedCSVError.new(I18n.t('criteria_csv_error.max_zero'))
      else
        raise CSV::IllegalFormatError.new(I18n.t('criteria_csv_error.max_zero'))
      end
    end
    criterion.description = row[2] if !row[2].nil?
    criterion.position = next_criterion_position(assignment)
    unless criterion.save
      if RUBY_VERSION > '1.9'
        raise CSV::MalformedCSVError.new(criterion.errors)
      else
        raise CSV::IllegalFormatError.new(criterion.errors)
      end
    end
    return criterion
  end

  # Parse a flexible criteria CSV file.
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
  #                 *Hint*: An array allows for easy
  #                 access to single invalid lines.
  #
  # ===Returns:
  #
  # The number of successfully created criteria.
  def self.parse_csv(file, assignment, invalid_lines = nil)
    nb_updates = 0
    CsvHelper::Csv.parse(file.read) do |row|
      next if CsvHelper::Csv.generate_line(row).strip.empty?
      if RUBY_VERSION > '1.9'
        begin
          FlexibleCriterion.new_from_csv_row(row, assignment)
          nb_updates += 1
        rescue CSV::MalformedCSVError => e
          invalid_lines << row.join(',') + ': ' + e.message unless invalid_lines.nil?
        end
      else
        begin
          FlexibleCriterion.new_from_csv_row(row, assignment)
          nb_updates += 1
        rescue CSV::IllegalFormatError => e
          invalid_lines << row.join(',') + ': ' + e.message unless invalid_lines.nil?
        end
      end
    end
    return nb_updates
  end

  # ===Returns:
  #
  # The position that should receive the next criterion for an assignment.
  def self.next_criterion_position(assignment)
    # TODO temporary, until Assignment gets its criteria method
    #      nevermind the fact that this computation should really belong in assignment
    last_criterion = FlexibleCriterion.find_last_by_assignment_id(assignment.id, :order => :position)
    return last_criterion.position + 1 unless last_criterion.nil?
    1
  end

  def get_weight
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
    associations = criterion_ta_associations.all(:conditions => {:ta_id => ta_array})
    ta_array.each do |ta|
      if (ta.criterion_ta_associations & associations).size < 1
        criterion_ta_associations.create(:ta => ta, :criterion => self, :assignment => self.assignment)
      end
    end
  end

  def get_name
    flexible_criterion_name
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
      criterion = FlexibleCriterion.find_by_assignment_id_and_flexible_criterion_name(assignment_id, criterion_name)
      if criterion.nil?
        failures.push(criterion_name)
      else
        criterion.add_tas_by_user_name_array(row) # The rest of the array
      end
    end
    return failures
  end

end
