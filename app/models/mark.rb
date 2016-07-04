class Mark < ActiveRecord::Base
  # When a mark is created, or updated, we need to make sure that that
  # Result has not been released to students
  before_save :ensure_not_released_to_students
  before_update :ensure_not_released_to_students

  after_save :update_result_mark

  belongs_to :result
  validates_presence_of :result_id, :markable_id, :markable_type
  validates_numericality_of :result_id,
                            only_integer: true,
                            greater_than: 0,
                            message: 'result_id must be an id that is an integer greater than 0'

  validates_numericality_of :mark,
                            allow_nil: true,
                            greater_than_or_equal_to: 0,
                            message: I18n.t('marker.marks.invalid_mark')
  validate :valid_mark

  belongs_to :markable, polymorphic: true
  validates_numericality_of :markable_id,
                            only_integer: true,
                            greater_than_or_equal_to: 0,
                            message: 'Criterion must be an id that is an integer greater than 0'

  validates_uniqueness_of :markable_id,
                          scope: [:result_id, :markable_type]

  # Custom validator for checking the upper range of a mark
  def valid_mark
    unless mark.nil?
      if mark > markable.max_mark
        errors.add(:mark, I18n.t('mark.error.validate_criteria'))
      end
    end
  end

  private

  def ensure_not_released_to_students
    !result.released_to_students
  end

  def update_result_mark
    result.update_total_mark
  end
end

