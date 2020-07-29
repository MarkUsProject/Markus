# Class joining a grouping to a starter code entry that has been given
# to the grouping as starter code.
class GroupingStarterCodeEntry < ApplicationRecord
  belongs_to :starter_code_entry
  belongs_to :grouping
end
