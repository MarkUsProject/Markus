class Section < ApplicationRecord
  validates :name, presence: true, uniqueness: true, allow_blank: false
  has_many :students
  has_many :section_due_dates
  has_many :section_starter_file_groups
  has_many :starter_file_groups, through: :section_starter_file_groups

  # Returns true when students are part of this section
  def has_students?
    !students.empty?
  end

  # returns the number of students in this section
  def count_students
    students.size
  end

  def section_due_date_for(aid)
    SectionDueDate.where(assessment_id: aid, section_id: id).first
  end

  def starter_file_group_for(assessment)
    starter_file_groups.where(assessment_id: assessment.id).first || assessment.default_starter_file_group
  end

  def update_starter_file_group(assessment_id, starter_file_group_id)
    return if starter_file_groups.where(assessment_id: assessment_id).first&.id == starter_file_group_id

    # delete all old section starter file groups
    section_starter_file_groups.where.not('starter_file_group_id': starter_file_group_id).each(&:destroy)

    unless starter_file_group_id.nil?
      SectionStarterFileGroup.find_or_create_by(section_id: self.id, starter_file_group_id: starter_file_group_id)
    end

    # mark all groupings with starter file that was changed as changed
    Grouping.joins(:inviter)
            .where('users.section_id': self.id)
            .where(assessment_id: assessment_id)
            .update_all(starter_file_changed: true)
  end
end
