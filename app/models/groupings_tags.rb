# rubocop:disable Layout/LineLength, Lint/RedundantCopDisableDirective
# == Schema Information
#
# Table name: groupings_tags
#
#  created_at  :datetime
#  updated_at  :datetime
#  grouping_id :integer          not null
#  tag_id      :integer          not null
#
# Indexes
#
#  index_groupings_tags_on_tag_id_and_grouping_id  (tag_id,grouping_id) UNIQUE
#
# rubocop:enable Layout/LineLength, Lint/RedundantCopDisableDirective
class GroupingsTags < ApplicationRecord
  belongs_to :grouping
  belongs_to :tag
end
