# Class joining a section to a starter file group. This starter file group
# is used to assign starter files to groups within a section for assessments
# with starter_file_rule_type == 'sections'
class SectionStarterFileGroup < ApplicationRecord
  belongs_to :starter_file_group
  belongs_to :section

  validates_presence_of :section
  validates_presence_of :starter_file_group
  validate :only_one_per_assessment

  private

  def only_one_per_assessment
    return if section.nil? || starter_file_group.nil?
    others = self.class
                 .joins(:starter_file_group)
                 .where('starter_file_groups.assessment_id': starter_file_group.assignment.id)
                 .where('section_id': self.section_id)
                 .where.not('starter_file_group_id': starter_file_group.id)
    errors.add(:base, 'Only one allowed per assessment') if others.exists?
  end
end
