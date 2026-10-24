# Class joining a grouping with a tag.
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
  self.primary_key = nil

  belongs_to :grouping
  belongs_to :tag

  has_one :course, through: :grouping

  validate :courses_should_match
  validate :assignments_should_match

  private

  def assignments_should_match
    return if tag.nil? || grouping.nil? || tag.assessment_id.nil?
    return if grouping.assessment_id == tag.assessment_id

    errors.add(:base, :different_assignment_grouping)
  end
end
