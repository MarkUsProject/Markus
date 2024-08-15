FactoryBot.define do
  factory :annotation_text, class: 'AnnotationText' do
    content { Faker::Lorem.sentence }
    created_at { Time.current }
    updated_at { Time.current }
    association :creator, factory: :instructor
    association :annotation_category
  end

  factory :annotation_text_with_deduction, parent: :annotation_text do
    deduction { 1.0 }
  end
end
