class AnnotationCategory < ApplicationRecord
  has_many :annotation_texts, dependent: :destroy

  validates_presence_of :annotation_category_name
  validates_uniqueness_of :annotation_category_name, scope: :assignment_id

  belongs_to :assignment

  # Takes an array of comma separated values, and tries to assemble an
  # Annotation Category, and associated Annotation Texts
  # Format:  annotation_category,annotation_text,annotation_text,...
  def self.add_by_row(row, assignment, current_user)
    # The first column is the annotation category name.
    name = row.shift
    annotation_category = assignment.annotation_categories.find_or_create_by(
      annotation_category_name: name
    )

    row.each do |text|
      annotation_text = annotation_category.annotation_texts.build(
        content: text,
        creator_id: current_user.id,
        last_editor_id: current_user.id
      )
      unless annotation_text.save
        raise CSVInvalidLineError
      end
    end
  end
end
