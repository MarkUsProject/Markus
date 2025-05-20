class Section < ApplicationRecord
  validates :name, presence: true, allow_blank: false,
                   format: { with: /\A[a-zA-Z0-9\-_ ]+\z/ }
  validates :name, uniqueness: { scope: :course_id }
  has_many :students
  has_many :assessment_section_properties, class_name: 'AssessmentSectionProperties'
  has_many :section_starter_file_groups
  has_many :starter_file_groups, through: :section_starter_file_groups

  belongs_to :course, inverse_of: :sections

  # Returns true when students are part of this section
  def has_students?
    !students.empty?
  end

  # returns the number of students in this section
  def count_students
    students.size
  end

  def starter_file_group_for(assessment)
    starter_file_groups.where(assessment_id: assessment.id).first || assessment.default_starter_file_group
  end

  def update_starter_file_group(assessment_id, starter_file_group_id)
    starter_files_groups_for_assignment = starter_file_groups.where(assessment_id: assessment_id)
    return if starter_files_groups_for_assignment.first&.id == starter_file_group_id

    # delete all old section starter file groups
    section_starter_file_groups.where(starter_file_group_id: starter_files_groups_for_assignment).find_each(&:destroy)

    unless starter_file_group_id.nil?
      SectionStarterFileGroup.find_or_create_by(section_id: self.id, starter_file_group_id: starter_file_group_id)
    end

    # mark all groupings with starter file that was changed as changed
    Grouping.joins(:inviter)
            .where('roles.section_id': self.id)
            .where(assessment_id: assessment_id)
            .update_all(starter_file_changed: true)
  end
end
