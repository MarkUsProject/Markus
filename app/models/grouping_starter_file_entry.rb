# Class joining a grouping to a starter file entry that has been given
# to the grouping as starter files.
class GroupingStarterFileEntry < ApplicationRecord
  belongs_to :starter_file_entry
  belongs_to :grouping
end
