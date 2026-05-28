# Class joining a grouping to a starter file entry that has been given
# to the grouping as starter files.
# rubocop:disable Layout/LineLength, Lint/RedundantCopDisableDirective
# == Schema Information
#
# Table name: grouping_starter_file_entries
#
#  id                    :bigint           not null, primary key
#  grouping_id           :bigint           not null
#  starter_file_entry_id :bigint           not null
#
# Indexes
#
#  index_grouping_starter_file_entries_on_grouping_id            (grouping_id)
#  index_grouping_starter_file_entries_on_starter_file_entry_id  (starter_file_entry_id)
#
# Foreign Keys
#
#  fk_rails_...  (grouping_id => groupings.id)
#  fk_rails_...  (starter_file_entry_id => starter_file_entries.id)
#
# rubocop:enable Layout/LineLength, Lint/RedundantCopDisableDirective
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
