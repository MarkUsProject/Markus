class AssignmentFile < ApplicationRecord

  belongs_to :assignment
  has_many :criteria_assignment_files_joins, dependent: :destroy
  has_many :template_divisions

  validates_presence_of :filename
  validates_uniqueness_of :filename, scope: :assignment_id
  before_validation do
    self.filename = Pathname.new(self.filename).cleanpath.to_s
  end
  validates_format_of :filename,
          with: /\A[\-\._a-zA-Z0-9][\/\-\._a-zA-Z0-9]*\z/,
          message: I18n.t('validation_messages.format_of_assignment_file')

end
