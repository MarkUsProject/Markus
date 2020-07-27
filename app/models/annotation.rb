class Annotation < ApplicationRecord

  belongs_to                :submission_file
  belongs_to                :annotation_text
  belongs_to                :creator, polymorphic: true
  belongs_to                :result

  validates_presence_of     :annotation_number
  validates_inclusion_of    :is_remark, in: [true, false]

  validates_associated      :submission_file, on: :create
  validates_associated      :annotation_text, on: :create
  validates_associated      :result, on: :create

  validates_numericality_of :annotation_number,
                            only_integer: true,
                            greater_than: 0

  validates_format_of :type,
                      with: /\AImageAnnotation|TextAnnotation|PdfAnnotation\z/

  after_create :modify_mark_with_deduction, unless: ->(a) { [nil, 0].include? a.annotation_text.deduction }
  after_destroy :modify_mark_with_deduction, unless: ->(a) { [nil, 0].include? a.annotation_text.deduction }

  def modify_mark_with_deduction
    criterion = self.annotation_text.annotation_category.flexible_criterion
    self.result.marks.find_by(criterion: criterion).update_deduction
  end

  def get_data(include_creator=false)
    data = {
      id: id,
      filename: submission_file.filename,
      path: submission_file.path.split('/', 2)[1], # Remove assignment folder
      submission_file_id: submission_file_id,
      annotation_text_id: annotation_text_id,
      content: annotation_text.content,
      annotation_category:
        annotation_text.annotation_category&.annotation_category_name,
      type: self.class.name,
      number: annotation_number,
      is_remark: is_remark,
      deduction: annotation_text.deduction,
      criterion_name: annotation_text.annotation_category&.flexible_criterion&.name,
      criterion_id: annotation_text.annotation_category&.flexible_criterion&.id
    }

    if include_creator
      data[:creator] = "#{creator.first_name} #{creator.last_name}"
    end

    data
  end
end
