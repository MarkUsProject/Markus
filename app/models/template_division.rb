class TemplateDivision < ActiveRecord::Base
  belongs_to :exam_template

  validates :start, numericality: { greater_than_or_equal_to: 1,
                                    only_integer: true }
  validates :end, numericality: { greater_than_or_equal_to: 1,
                                  only_integer: true }
  validates :label, uniqueness: true, allow_blank: false
end
