class SplitPdfLog < ApplicationRecord
  belongs_to :role
  belongs_to :exam_template
  has_many :split_pages, dependent: :destroy
  has_one :course, through: :role
  after_initialize :set_defaults_for_uploaded_when, unless: :persisted? # will only work if the object is new
  validates :filename, :num_groups_in_complete, :num_groups_in_incomplete, :num_pages_qr_scan_error,
            :original_num_pages, presence: true
  validates :num_groups_in_complete, :num_groups_in_complete, :num_pages_qr_scan_error, :original_num_pages,
            numericality: { greater_than_or_equal_to: 0,
                            only_integer: true }

  validate :courses_should_match

  private

  def set_defaults_for_uploaded_when
    # Attribute 'uploaded_when' of split_pdf_log is by default set to the time the object gets created.
    self.uploaded_when = Time.current
  end
end
