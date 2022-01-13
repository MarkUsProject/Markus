class Note < ApplicationRecord
  belongs_to :noteable, polymorphic: true

  validates_presence_of :notes_message

  belongs_to :role, foreign_key: :creator_id
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
end
