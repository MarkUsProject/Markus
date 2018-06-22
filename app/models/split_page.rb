class SplitPage < ApplicationRecord
  belongs_to :split_pdf_log
  belongs_to :group, optional: true
  validates :split_pdf_log, :filename, :raw_page_number, presence: true
  validates :raw_page_number,
            numericality: { greater_than_or_equal_to: 1,
                            only_integer: true }
  validates :exam_page_number,
            numericality: { greater_than_or_equal_to: 1,
                            only_integer: true,
                            allow_blank: true }
end
