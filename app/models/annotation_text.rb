class AnnotationText < ApplicationRecord

  belongs_to :creator, class_name: 'User', foreign_key: :creator_id
  belongs_to :last_editor, class_name: 'User', foreign_key: :last_editor_id, optional: true

  # An AnnotationText has many Annotations that are destroyed when an
  # AnnotationText is destroyed.
  has_many :annotations, dependent: :destroy

  belongs_to :annotation_category, optional: true, counter_cache: true
  validates_associated :annotation_category, on: :create

  def escape_content
    content.gsub('\\', '\\\\\\') # Replaces '\\' with '\\\\'
           .gsub(/\r?\n/, '\\n')
  end

  def get_stats
    applications = []
    self.annotations.each do |instance|
      instance_info = {
        applier: User.find_by(id: instance.creator_id).user_name,
        grouping_name: get_grouping_name(instance.result.grouping.id),
        link: 'text link'
      }
      # url_for(Rails.application.routes.url_helpers.edit_assignment_submission_result_path(
      #     instance.result.grouping.assignment.id,
      #     instance.result.submission_id,
      #     instance.result.id)
      # )
      applications << instance_info
    end
    stats = {
      num_times_used: self.annotations.count,
      uses: applications
    }
    stats
  end
  def get_grouping_name(grouping_id)
    grouping = Grouping.find_by(id: grouping_id)
    name = ''
    grouping.accepted_students.each do |member|
      name += member.user_name + ', '
    end
    name[0...-2]
  end
end
