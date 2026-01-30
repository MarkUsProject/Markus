class Annotation < ApplicationRecord
  belongs_to :submission_file
  belongs_to :annotation_text
  belongs_to :creator, polymorphic: true
  belongs_to :result

  has_one :course, through: :submission_file

  validate :courses_should_match
  validates :annotation_number, presence: true
  validates :is_remark, inclusion: { in: [true, false] }

  validates_associated :submission_file, on: :create
  validates_associated :annotation_text, on: :create
  validates_associated :result, on: :create

  validates :annotation_number,
            numericality: { only_integer: true,
                            greater_than: 0 }

  validates :type,
            format: { with: /\AImageAnnotation|TextAnnotation|PdfAnnotation|HtmlAnnotation\z/ }

  before_create :check_if_released
  after_create :modify_mark_with_deduction, unless: ->(a) { [nil, 0].include? a.annotation_text.deduction }

  before_destroy :check_if_released
  after_destroy :modify_mark_with_deduction, unless: ->(a) { [nil, 0].include? a.annotation_text.deduction }

  def modify_mark_with_deduction
    criterion = self.annotation_text.annotation_category.flexible_criterion
    self.result.marks.find_or_create_by(criterion: criterion).update_deduction unless self.is_remark
  end

  def get_data(include_creator: false)
    data = {
      id: id,
      filename: submission_file.filename,
      path: submission_file.path.split('/', 2)[1], # Remove assignment folder
      submission_file_id: submission_file_id,
      annotation_text_id: annotation_text_id,
      content: annotation_text.content || '',
      annotation_category:
        annotation_text.annotation_category&.annotation_category_name,
      annotation_category_id: annotation_text.annotation_category_id,
      type: self.class.name,
      number: annotation_number,
      is_remark: is_remark,
      deduction: annotation_text.deduction,
      criterion_name: annotation_text.annotation_category&.flexible_criterion&.name,
      criterion_id: annotation_text.annotation_category&.flexible_criterion&.id
    }
    if include_creator
      data[:creator] = creator.present? ? creator.display_name : I18n.t('deleted_placeholder')
    end

    data
  end

  private

  # check if the submission file is associated with a remark result or a released result
  def check_if_released
    annotation_results = result.submission.non_pr_results

    return if is_remark && annotation_results.where.not(remark_request_submitted_at: nil)
                                             .where('results.released_to_students': false)

    return if annotation_results.where('results.released_to_students': true).empty? &&
              annotation_results.where.not(remark_request_submitted_at: nil).empty?

    return if result.is_a_review? && !result.released_to_students

    errors.add(:base, :results_already_released)
    throw(:abort)
  end
end
