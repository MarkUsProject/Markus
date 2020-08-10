# Class joining a grouping to a starter file entry that has been given
# to the grouping as starter files.
class GroupingStarterFileEntry < ApplicationRecord
  belongs_to :starter_file_entry
  belongs_to :grouping

  validates_presence_of :grouping
  validates_presence_of :starter_file_entry
  validates_uniqueness_of :starter_file_entry_id, scope: :grouping_id
end
