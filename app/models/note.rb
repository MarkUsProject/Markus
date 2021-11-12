class Note < ApplicationRecord
  belongs_to :noteable, polymorphic: true

  validates_presence_of :notes_message

  belongs_to :role, foreign_key: :creator_id
  validates_associated :role

  has_one :course, through: :role

  NOTEABLES = %w(Grouping Student Assignment)

  def format_date
    I18n.l(created_at)
  end

  def self.noteables_exist?
    NOTEABLES.each do |classname|
      unless Kernel.const_get(classname).all.empty?
        return true
      end
    end
    false
  end
end
