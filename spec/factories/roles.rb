FactoryBot.define do
  factory :role do
    association :human
    course { Course.first || association(:course) }
  end
end
