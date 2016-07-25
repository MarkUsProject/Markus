class Section < ActiveRecord::Base
  validates :name, presence: true, uniqueness: true, allow_blank: false
  has_many :students
  has_many :section_due_dates

  # Returns true when students are part of this section
  def has_students?
    !students.empty?
  end

  # returns the number of students in this section
  def count_students
    students.size
  end

  def section_due_date_for(aid)
    SectionDueDate.where(assignment_id: aid, section_id: id).first
  end

  def user_can_modify?(current_user)
    current_user.admin?
  end
end
