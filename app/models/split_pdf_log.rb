class SplitPdfLog < ActiveRecord::Base
  after_initialize :set_defaults_for_uploaded_when, unless: :persisted? # will only work if the object is new
  belongs_to :user
  validates :filename,
            :num_groups_in_complete, :num_groups_in_incomplete, :num_pages_qr_scan_error,
            :original_num_pages, presence: true

  private
  def set_defaults_for_uploaded_when
    # Attribute 'uploaded_when' of split_pdf_log is by default set to the time the object gets created.
    self.uploaded_when = DateTime.now
  end
end
