FactoryBot.define do
  factory :annotation_category, class: 'AnnotationCategory' do
    annotation_category_name { Faker::Lorem.sentence }
    created_at { Time.current }
    updated_at { Time.current }
    association :assignment
  end
end
