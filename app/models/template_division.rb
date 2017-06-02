class TemplateDivision < ActiveRecord::Base
  belongs_to :exam_template
  belongs_to :criteria_assignment_files_join, dependent: :destroy

  accepts_nested_attributes_for :criteria_assignment_files_join

  validates :start, numericality: { greater_than_or_equal_to: 1,
                                    less_than_or_equal_to: :end,
                                    only_integer: true }
  validates :end, numericality: { less_than_or_equal_to: TemplateDivision.first.exam_template.num_pages,
                                  only_integer: true }
  validates :label, uniqueness: true, allow_blank: false

  after_destroy :destroy_associated_objects

  def self.create_with_associations(assignment_id, attributes)
    attributes.merge! ({
      criteria_assignment_files_join_attributes: {
        assignment_file_attributes: {
          filename: "#{attributes[:label]}.pdf",
          assignment_id: assignment_id
        },
        criterion_attributes: {
          name: attributes[:label],
          assignment_id: assignment_id
        }
      }
    })
    create(attributes)
  end

  def hash
    [self.start, self.end, self.label].hash
  end

  private
  def destroy_associated_objects
    assignment_file = criteria_assignment_files_join.assignment_file
    criterion = criteria_assignment_files_join.criterion
    # Note: this destroys the join record as well.
    assignment_file.destroy
    criterion.destroy
  end

end
