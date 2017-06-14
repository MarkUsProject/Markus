class TemplateDivision < ActiveRecord::Base
  belongs_to :exam_template
  belongs_to :criteria_assignment_files_join, dependent: :destroy

  accepts_nested_attributes_for :criteria_assignment_files_join, allow_destroy: true

  validates :start, numericality: { greater_than_or_equal_to: 1,
                                    less_than_or_equal_to: :end,
                                    only_integer: true }
  validates :end, numericality: { only_integer: true }
  validate :end_should_be_less_than_or_equal_to_num_pages
  validates :label, uniqueness: true, allow_blank: false

  after_destroy :destroy_associated_objects
  after_save :set_defaults_for_associated_criteria_assignment_files_join # when template division is create or updated

  def hash
    [self.start, self.end, self.label].hash
  end

  def end_should_be_less_than_or_equal_to_num_pages
    errors.add(:end, "should be less than or equal to num_pages") unless self.end <= self.exam_template.num_pages
  end

  private
  def destroy_associated_objects
    assignment_file = criteria_assignment_files_join.assignment_file
    criterion = criteria_assignment_files_join.criterion
    # Note: this destroys the join record as well.
    assignment_file.destroy
    criterion.destroy
  end


  def set_defaults_for_associated_criteria_assignment_files_join
    if criteria_assignment_files_join.nil?
      assignment_file = AssignmentFile.create(
        filename: "#{exam_template.name}-#{label}.pdf",
        assignment_id: exam_template.assignment.id
      )
      criterion = FlexibleCriterion.create(
        max_mark: 1.0,
        name: "#{exam_template.name}-#{label}",
        assignment_id: exam_template.assignment.id
      )
      criteria_assignment_files_join_object = CriteriaAssignmentFilesJoin.create(
        assignment_file: assignment_file,
        criterion: criterion
      )
      self.update(criteria_assignment_files_join: criteria_assignment_files_join_object)
    else
      criteria_assignment_files_join.assignment_file.filename = "#{exam_template.name}-#{label}.pdf"
      criteria_assignment_files_join.assignment_file.assignment_id = exam_template.assignment.id
      criteria_assignment_files_join.criterion.name = "#{exam_template.name}-#{label}"
      criteria_assignment_files_join.criterion.assignment_id = exam_template.assignment.id
      criteria_assignment_files_join.save!
    end
  end

end
