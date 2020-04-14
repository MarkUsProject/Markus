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
end
