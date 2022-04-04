FactoryBot.define do
  factory :role do
    association :user
    course { Course.order(:id).first || association(:course) }
  end
end
