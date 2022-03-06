class AssignmentFile < ApplicationRecord
  belongs_to :assignment, foreign_key: :assessment_id, inverse_of: :assignment_files
  has_many :criteria_assignment_files_joins, dependent: :destroy
  has_many :template_divisions
  has_one :course, through: :assignment

  before_validation :clean_filename
  validates :filename, presence: true
  validates :filename, uniqueness: { scope: :assessment_id }
  validates :filename, format: { with: %r{\A[\-._a-zA-Z0-9][/\-._a-zA-Z0-9]*\z} }

  private

  def clean_filename
    self.filename = Pathname.new(self.filename).cleanpath.to_s if self.filename.present?
  end
end
