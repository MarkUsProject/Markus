# Model representing a user's role in a given course.
class Role < ApplicationRecord
  belongs_to :user
  belongs_to :course
  accepts_nested_attributes_for :user

  validates_format_of :type, with: /\AStudent|Admin|Ta\z/

  # role constants
  STUDENT = 'Student'.freeze
  ADMIN = 'Admin'.freeze
  TA = 'Ta'.freeze

  # Helper methods -----------------------------------------------------

  def admin?
    instance_of?(Admin)
  end

  def ta?
    instance_of?(Ta)
  end

  def student?
    instance_of?(Student)
  end
end
