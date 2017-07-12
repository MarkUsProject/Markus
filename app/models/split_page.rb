class SplitPage < ActiveRecord::Base
  belongs_to :split_pdf_log
  belongs_to :group
  validates :filename, :raw_page_number, presence: true
  validates :raw_page_number, :exam_page_number,
            numericality: { greater_than_or_equal_to: 0,
                            only_integer: true,
                            allow_blank: true }
end
