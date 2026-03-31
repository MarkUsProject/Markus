# rubocop:disable Layout/LineLength, Lint/RedundantCopDisableDirective
# == Schema Information
#
# Table name: assignment_files
#
#  id            :integer          not null, primary key
#  filename      :string           not null
#  created_at    :datetime
#  updated_at    :datetime
#  assessment_id :bigint
#
# Indexes
#
#  index_assignment_files_on_assessment_id               (assessment_id)
#  index_assignment_files_on_assessment_id_and_filename  (assessment_id,filename) UNIQUE
#
# Foreign Keys
#
#  fk_assignment_files_assignments  (assessment_id => assessments.id) ON DELETE => cascade
#
# rubocop:enable Layout/LineLength, Lint/RedundantCopDisableDirective
class AssignmentFile < ApplicationRecord
  belongs_to :assignment, foreign_key: :assessment_id, inverse_of: :assignment_files
  has_many :criteria_assignment_files_joins, dependent: :destroy
  has_many :template_divisions, dependent: :destroy
  has_one :course, through: :assignment

  before_validation :clean_filename
  validates :filename, presence: true
  validates :filename, uniqueness: { scope: :assessment_id }
  validates :filename, format: { with: %r{\A[-._a-zA-Z0-9][-/._a-zA-Z0-9\s]*\z} }

  private

  def clean_filename
    self.filename = Pathname.new(self.filename).cleanpath.to_s if self.filename.present?
  end
end
