FactoryBot.define do
  factory :marking_scheme do
    transient do
      assessments { [] }
    end
    name { Faker::Lorem.sentence }

    after(:create) do |marking_scheme, evaluator|
      for assessment in evaluator.assessments
        create(:marking_weight, marking_scheme: marking_scheme, assessment: assessment)
      end
    end
  end
end
