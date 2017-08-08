FactoryGirl.define do
  factory :annotation_text, class: AnnotationText do
    content { Faker::Lorem.sentence }
    created_at { Time.now }
    updated_at { Time.now }
    user { FactoryGirl.create(:admin) }
    association :annotation_category, factory: :annotation_category
  end
end
