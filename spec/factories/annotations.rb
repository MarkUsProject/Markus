require 'faker'

FactoryBot.define do
  factory :annotation do
    association :annotation_text
    association :submission_file
    association :creator, factory: :admin
    association :result, factory: :complete_result
    sequence(:annotation_number)
    creator_type { 'Admin' }
    is_remark { false }

    factory :image_annotation, class: ImageAnnotation do
      x1 { 1 }
      x2 { 2 }
      y1 { 1 }
      y2 { 2 }
    end
  end
end
