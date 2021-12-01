FactoryBot.define do
  factory :role do
    association :human
    course { Course.order(:id).first || association(:course) }
  end
end
