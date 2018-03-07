class Note < ApplicationRecord
  belongs_to :noteable, polymorphic: true, counter_cache: true

  validates_presence_of :notes_message, :creator_id, :noteable

  belongs_to :user, foreign_key: :creator_id, counter_cache: true
  validates_associated :user

  NOTEABLES = %w(Grouping Student Assignment)

  def user_can_modify?(current_user)
    current_user.admin? || user == current_user
  end

  def format_date
    I18n.l(created_at, format: :long_date)
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
