class SplitPage < ActiveRecord::Base
  belongs_to :exam_template
  belongs_to :group, optional: true
  validates :exam_template, :filename, :page_number, presence: true
  validates :page_number,
            numericality: { greater_than_or_equal_to: 0,
                            only_integer: true }
end
