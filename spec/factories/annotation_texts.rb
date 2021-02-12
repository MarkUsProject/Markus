FactoryBot.define do
  factory :annotation_text, class: AnnotationText do
    content { Faker::Lorem.sentence }
    created_at { Time.current }
    updated_at { Time.current }
    creator { FactoryBot.create(:admin) }
    association :annotation_category, factory: :annotation_category
    association :last_editor, factory: :admin
  end

  factory :annotation_text_with_deduction, parent: :annotation_text do
    deduction { 1.0 }
  end
end
