# Model representing a user's role in a given course.
class Role < ApplicationRecord
  belongs_to :user
  belongs_to :course
  accepts_nested_attributes_for :user

  # Group relationships
  has_many :memberships, dependent: :delete_all
  has_many :grade_entry_students
  has_many :groupings, through: :memberships
  has_many :notes, as: :noteable, dependent: :destroy
  has_many :accepted_memberships,
           -> { where membership_status: [StudentMembership::STATUSES[:accepted], StudentMembership::STATUSES[:inviter]] },
           class_name: 'Membership'
  has_many :annotations, as: :creator
  has_many :test_runs, dependent: :destroy
  has_many :split_pdf_logs

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
