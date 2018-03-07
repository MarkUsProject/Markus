class AssignmentFile < ApplicationRecord

  belongs_to :assignment
  has_many :criteria_assignment_files_joins, dependent: :destroy
  has_many :template_divisions

  validates_presence_of :filename
  validates_uniqueness_of :filename, scope: :assignment_id
  validates_format_of :filename,
          with: /\A[0-9a-zA-Z\.\-_\(\)]+\z/,
          message: I18n.t('validation_messages.format_of_assignment_file')

end
