# Class describing a course
class Course < ApplicationRecord
  validates_presence_of :name, presence: true, uniqueness: true
end
