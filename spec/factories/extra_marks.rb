FactoryBot.define do
  factory :extra_mark, class: 'ExtraMark' do
    association :result
    description { Faker::Lorem.sentence }
    unit { 'percentage' }
    extra_mark { -10.0 }

    factory :extra_mark_percentage do
      unit { 'percentage' }
      extra_mark { -10.0 }
    end

    factory :extra_mark_marks do
      unit { 'marks' }
      extra_mark { 1 }
    end

    factory :extra_mark_percentage_of_mark do
      unit { 'percentage_of_mark' }
      extra_mark { 5.0 }
    end
  end
end
