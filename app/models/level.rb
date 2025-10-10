# Level represents a level within a Rubric Criterion
class Level < ApplicationRecord
  belongs_to :criterion

  has_one :course, through: :criterion
  attr_accessor :skip_uniqueness_validation

  validates :name, presence: true

  validates :description, exclusion: { in: [nil] }

  validates :mark, presence: true
  validates :mark, numericality: { greater_than_or_equal_to: 0 }

  validate :only_update_if_results_unreleased
  validate :unique_name_within_criterion, unless: :skip_uniqueness_validation
  validate :unique_mark_within_criterion, unless: :skip_uniqueness_validation

  before_update :update_associated_marks
  before_destroy :destroy_associated_marks

  # Validates that a name is unique
  #
  # Custom validators have access to in memory data and can be used to validate final state changes.
  # By contrast, built-in rails uniqueness validators query the database,
  # their information limited, to pre-updated records
  #
  # Built in validators run into the issue of constraint infractions.
  # This happens when an attempt is made to swap two values within the same transaction.
  # Each record is compared against the database before the second has had a chance to update.
  def unique_name_within_criterion
    return unless criterion
    return unless will_save_change_to_name? || new_record?

    siblings = criterion.levels.reject { |level| level.id == id || level.marked_for_destruction? }
    duplicate = siblings.find { |level| level.name == name }
    errors.add(:name, :taken) if duplicate
  end

  # Validates that a mark is unique
  #
  # Custom validators have access to in memory data and can be used to validate final state changes.
  # By contrast, built-in rails uniqueness validators query the database,
  # their information limited, to pre-updated records
  #
  # Built in validators run into the issue of constraint infractions.
  # This happens when an attempt is made to swap two values within the same transaction.
  # Each record is compared against the database before the second has had a chance to update.
  def unique_mark_within_criterion
    return unless criterion
    return unless will_save_change_to_mark? || new_record?

    siblings = criterion.levels.reject { |level| level.id == id || level.marked_for_destruction? }
    duplicate = siblings.find { |level| level.mark == mark }
    errors.add(:mark, :taken) if duplicate
  end

  def only_update_if_results_unreleased
    return if self.criterion.nil? # When the level is first being created
    unless self.criterion.results_unreleased?
      errors.add(:base, 'Cannot update level once results are released.')
    end
  end

  def destroy_associated_marks
    self.criterion.marks.where(mark: self.mark).update(mark: nil)
  end

  def update_associated_marks
    return unless self.changed.include?('mark')
    old_mark, new_mark = self.changes['mark']
    if self.criterion.changes.include?('max_mark')
      old_max_mark, new_max_mark = self.criterion.changes['max_mark']
      # Skip update if this change is caused
      return if old_mark * new_max_mark == new_mark * old_max_mark
    end
    self.criterion.marks.where(mark: old_mark).update(mark: new_mark)
  end
end
