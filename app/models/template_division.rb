class TemplateDivision < ApplicationRecord
  belongs_to :exam_template
  belongs_to :assignment_file, optional: true

  accepts_nested_attributes_for :assignment_file, allow_destroy: true

  validates :start, numericality: { greater_than_or_equal_to: 1,
                                    less_than_or_equal_to: :end,
                                    only_integer: true }
  validates :end, numericality: { only_integer: true }
  validate :end_should_be_less_than_or_equal_to_num_pages
  validates_uniqueness_of :label,
                          scope: :exam_template,
                          allow_blank: false

  after_save :set_defaults_for_assignment_file # when template division is created or updated

  def hash
    [self.start, self.end, self.label].hash
  end

  def end_should_be_less_than_or_equal_to_num_pages
    errors.add(:end, "should be less than or equal to num_pages") unless self.end <= self.exam_template.num_pages
  end

  def set_defaults_for_assignment_file
    filename =  "#{exam_template.name}-#{label}.pdf".tr(' ', '_')
    if assignment_file.nil?
      assignment_file_object = AssignmentFile.find_or_initialize_by(
        filename: filename,
        assignment_id: exam_template.assignment.id
      )
      self.update(assignment_file: assignment_file_object)
    else
      assignment_file.filename = filename
      assignment_file.save!
    end
  end
end
