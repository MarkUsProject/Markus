class Note < ApplicationRecord
  belongs_to :noteable, polymorphic: true

  validates :notes_message, presence: true

  belongs_to :role, foreign_key: :creator_id # rubocop:disable Rails/InverseOf
  validates_associated :role

  has_one :course, through: :role
  validate :courses_should_match

  NOTEABLES = %w[Grouping Student Assignment].freeze

  def format_date
    I18n.l(created_at)
  end

  def self.noteables_exist?(course_id)
    NOTEABLES.each do |classname|
      unless classname.constantize.joins(:course).where('courses.id': course_id).empty?
        return true
      end
    end
    false
  end

  def self.get_noteable(class_name)
    case class_name
    when 'Grouping'
      Grouping
    when 'Student'
      Student
    when 'Assignment'
      Assignment
    else
      raise "Invalid noteable class #{class_name}"
    end
  end
end
