FactoryBot.define do
  factory :role do
    association :end_user
    course { Course.order(:id).first || association(:course) }
  end
end
