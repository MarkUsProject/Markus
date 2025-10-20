FactoryBot.define do
  factory :extra_mark, class: 'ExtraMark' do
    association :result
    description { Faker::Lorem.sentence }
    unit { ExtraMark::PERCENTAGE }
    extra_mark { -10.0 }

    factory :extra_mark_percentage do
      unit { ExtraMark::PERCENTAGE }
      extra_mark { -10.0 }
    end

    factory :extra_mark_points do
      unit { ExtraMark::POINTS }
      extra_mark { 1 }
    end

    factory :extra_mark_percentage_of_score do
      unit { ExtraMark::PERCENTAGE_OF_SCORE }
      extra_mark { 5.0 }
    end
  end
end
