class Section < ActiveRecord::Base
  validates_presence_of :name
  validates_uniqueness_of :name
  has_many :students

  # Returns true when students are part of this section
  # TODO unit tests
  def has_students?
    return !students.empty?  
  end

  # returns the number of students in this section
  # TODO unit test
  def count_students
    return students.size
  end

end
