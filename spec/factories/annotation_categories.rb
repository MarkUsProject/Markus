FactoryGirl.define do
  factory :annotation_category, class: AnnotationCategory do
    annotation_category_name { Faker::Lorem.sentence }
    created_at { Time.now }
    updated_at { Time.now }
    association :assignment, factory: :assignment
  end
end
