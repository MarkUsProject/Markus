require 'encoding'

# Represents a flexible criterion used to mark an assignment that
# has the marking_scheme_type attribute set to 'flexible'.
class FlexibleCriterion < Criterion

  self.table_name = 'flexible_criteria' # set table name correctly

  has_many :marks, as: :markable, dependent: :destroy

  has_many :criterion_ta_associations,
           as: :criterion,
           dependent: :destroy

  has_many :tas, through: :criterion_ta_associations

  validates_presence_of :flexible_criterion_name
  validates_uniqueness_of :flexible_criterion_name,
                          scope: :assignment_id,
                          message: I18n.t('flexible_criteria.errors.messages.name_taken')

  belongs_to :assignment, counter_cache: true
  validates_presence_of :assignment_id
  validates_associated :assignment,
                       message: 'association is not strong with an assignment'
  validates_numericality_of :assignment_id,
                            only_integer: true,
                            greater_than: 0,
                            message: 'can only be whole number greater than 0'

  validates_presence_of :max
  validates_numericality_of :max,
                            message: 'must be a number greater than 0.0',
                            greater_than: 0.0

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
    CSV.generate do |csv|
      # TODO temporary until Assignment gets its criteria method
      criteria = FlexibleCriterion.where(assignment_id: assignment.id)
                                  .order(:position)
      criteria.each do |c|
        criterion_array = [c.flexible_criterion_name, c.max, c.description]
        csv << criterion_array
      end
    end
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
  # CSV::MalformedCSVError::  If the row does not contains enough information, if the max value
  #                           is zero (or doesn't evaluate to a float) or if the
  #                           supplied name is not unique.
  def self.new_from_csv_row(row, assignment)
    if row.length < 2
      raise CSV::MalformedCSVError, I18n.t('criteria_csv_error.incomplete_row')
    end
    criterion = FlexibleCriterion.new
    criterion.assignment = assignment
    criterion.flexible_criterion_name = row[0]
    # assert that no other criterion uses the same name for the same assignment.
    unless FlexibleCriterion.where(assignment_id: assignment.id,
                                   flexible_criterion_name: row[0]).size.zero?
      message = I18n.t('criteria_csv_error.name_not_unique')
      raise CSV::MalformedCSVError, message
    end

    criterion.max = row[1]
    if criterion.max.zero?
      raise CSV::MalformedCSVError, I18n.t('criteria_csv_error.max_zero')
    end

    criterion.description = row[2] if !row[2].nil?
    criterion.position = next_criterion_position(assignment)

    unless criterion.save
      raise CSV::MalformedCSVError, criterion.errors
    end

    criterion
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
    CSV.parse(file.read) do |row|
      next if CSV.generate_line(row).strip.empty?
      begin
        FlexibleCriterion.new_from_csv_row(row, assignment)
        nb_updates += 1
      rescue CSV::MalformedCSVError => e
        unless invalid_lines.nil?
          invalid_lines << row.join(',') + ': ' + e.message
        end
      end
    end

    nb_updates
  end

  # ===Returns:
  #
  # The position that should receive the next criterion for an assignment.
  def self.next_criterion_position(assignment)
    # TODO temporary, until Assignment gets its criteria method
    #      nevermind the fact that this computation should really belong in assignment
    last_criterion = FlexibleCriterion.where(assignment_id: assignment.id)
                                      .order(:position)
                                      .last
    if last_criterion.nil?
      1
    else
      last_criterion.position + 1
    end
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
    associations = criterion_ta_associations.where(ta_id: ta_array)
    ta_array.each do |ta|
      if (ta.criterion_ta_associations & associations).size < 1
        criterion_ta_associations.create(ta: ta,
                                         criterion: self,
                                         assignment: self.assignment)
      end
    end
  end

  def get_name
    flexible_criterion_name
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
      Ta.where(user_name: ta_user_name).first
    end.compact
    add_tas(result)
  end

end
