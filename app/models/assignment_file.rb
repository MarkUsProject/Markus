class AssignmentFile < ApplicationRecord

  belongs_to :assignment, foreign_key: :assessment_id
  has_many :criteria_assignment_files_joins, dependent: :destroy
  has_many :template_divisions
  has_one :course, through: :assignment

  before_validation :clean_filename
  validates_presence_of :filename
  validates_uniqueness_of :filename, scope: :assessment_id
  validates_format_of :filename, with: %r{\A[\-\._a-zA-Z0-9][/\-\._a-zA-Z0-9]*\z}

  private

  def clean_filename
    self.filename = Pathname.new(self.filename).cleanpath.to_s unless self.filename.blank?
  end
end
