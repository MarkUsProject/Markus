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

  def uses
    # TODO: simplify second join once creator is no longer polymoprhic
    return self.annotations.joins(result: { grouping: :group })
                           .joins('INNER JOIN users ON annotations.creator_id = users.id')
                           .order('groups.group_name')
                           .group('results.id',
                                  'groupings.assessment_id',
                                  'results.submission_id',
                                  'groups.group_name',
                                  'users.first_name',
                                  'users.last_name',
                                  'users.user_name')
                           .pluck_to_hash('results.id AS result_id',
                                          'groupings.assessment_id AS assignment_id',
                                          'results.submission_id AS submission_id',
                                          'groups.group_name AS group_name',
                                          'users.first_name AS first_name',
                                          'users.last_name AS last_name',
                                          'users.user_name AS user_name',
                                          'count(*) AS count')
  end
end
