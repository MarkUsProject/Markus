# Class joining a grouping to a starter file entry that has been given
# to the grouping as starter files.
class GroupingStarterFileEntry < ApplicationRecord
  belongs_to :starter_file_entry
  belongs_to :grouping

  has_one :course, through: :grouping

  validate :assignments_should_match
  validates :starter_file_entry_id, uniqueness: { scope: :grouping_id }

  private

  def assignments_should_match
    return if starter_file_entry.nil? || grouping.nil?
    unless grouping.assignment == starter_file_entry.starter_file_group.assignment
      errors.add(:base, :not_in_same_assignment)
    end
  end
end
