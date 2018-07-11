class Annotation < ApplicationRecord

  belongs_to                :submission_file
  belongs_to                :annotation_text
  belongs_to                :creator, polymorphic: true
  belongs_to                :result

  validates_presence_of     :annotation_number
  validates_inclusion_of    :is_remark, in: [true, false]

  validates_associated      :submission_file
  validates_associated      :annotation_text
  validates_associated      :result

  validates_numericality_of :annotation_number,
                            only_integer: true,
                            greater_than: 0

  validates_format_of :type,
                      with: /\AImageAnnotation|TextAnnotation|PdfAnnotation\z/

  def get_data(include_creator=false)
    data = {
      id: id,
      file: File.join(submission_file.path,
                      submission_file.filename),
      submission_file_id: submission_file_id,
      annotation_text_id: annotation_text_id,
      content: annotation_text.content,
      annotation_category:
        annotation_text.annotation_category&.annotation_category_name,
      type: self.class.name,
      number: annotation_number,
      is_remark: is_remark
    }

    if include_creator
      data[:creator] = "#{creator.first_name} #{creator.last_name}"
    end

    data
  end
end
