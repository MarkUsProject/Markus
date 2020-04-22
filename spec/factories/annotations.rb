require 'faker'

FactoryBot.define do
  factory :annotation do
    association :annotation_text
    association :submission_file
    association :creator, factory: :admin
    association :result, factory: :complete_result
    sequence(:annotation_number)
    is_remark { false }

    factory :image_annotation, class: ImageAnnotation do
      x1 { 1 }
      x2 { 2 }
      y1 { 1 }
      y2 { 2 }

      factory :pdf_annotation, class: PdfAnnotation do
        page { 1 }
      end
    end

    factory :text_annotation, class: TextAnnotation do
      line_start { 1 }
      line_end { 2 }
      column_start { 1 }
      column_end { 2 }
    end
  end
end
