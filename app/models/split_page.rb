class SplitPage < ApplicationRecord
  belongs_to :split_pdf_log
  belongs_to :group, optional: true
  has_one :course, through: :split_pdf_log
  validates :raw_page_number,
            numericality: { greater_than_or_equal_to: 1,
                            only_integer: true }
  validates :exam_page_number,
            numericality: { greater_than_or_equal_to: 1,
                            only_integer: true,
                            allow_blank: true }
  validate :courses_should_match
end
