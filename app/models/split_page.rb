# rubocop:disable Layout/LineLength, Lint/RedundantCopDisableDirective
# == Schema Information
#
# Table name: split_pages
#
#  id               :integer          not null, primary key
#  exam_page_number :integer
#  filename         :string
#  raw_page_number  :integer
#  status           :string
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  group_id         :integer
#  split_pdf_log_id :integer
#
# Indexes
#
#  index_split_pages_on_group_id          (group_id)
#  index_split_pages_on_split_pdf_log_id  (split_pdf_log_id)
#
# Foreign Keys
#
#  fk_rails_...  (group_id => groups.id)
#  fk_rails_...  (split_pdf_log_id => split_pdf_logs.id)
#
# rubocop:enable Layout/LineLength, Lint/RedundantCopDisableDirective
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
