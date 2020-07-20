class Section < ApplicationRecord
  validates :name, presence: true, uniqueness: true, allow_blank: false
  has_many :students
  has_many :section_due_dates
  has_many :section_starter_code_groups
  has_many :starter_code_groups, through: :section_starter_code_groups

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

  def starter_code_group_for(assessment)
    starter_code_groups.where(assessment_id: assessment.id).first || assessment.default_starter_code_group
  end
end
