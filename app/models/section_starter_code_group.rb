# Class joining a section to a starter code group. This starter code group
# is used to assign starter code to groups within a section for assessments
# with starter_code_rule_type == 'sections'
class SectionStarterCodeGroup < ApplicationRecord
  belongs_to :starter_code_group
  belongs_to :section

  validate :only_one_per_assessment

  private

  def only_one_per_assessment
    others = self.class
                 .joins(:starter_code_group)
                 .where('starter_code_groups.assessment_id': starter_code_group&.assignment&.id)
                 .where('section_id': self.id)
                 .where.not('starter_code_group_id': starter_code_group&.id)
    errors.add(:base, 'Only one allowed per assessment') if others.exists?
  end
end
