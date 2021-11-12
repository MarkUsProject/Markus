FactoryBot.define do
  factory :marking_scheme do
    association :course
    transient do
      assessments { [] }
    end
    name { Faker::Lorem.sentence }

    after(:create) do |marking_scheme, evaluator|
      evaluator.assessments.each do |assessment|
        create(:marking_weight, marking_scheme: marking_scheme, assessment: assessment)
      end
    end
  end
end
