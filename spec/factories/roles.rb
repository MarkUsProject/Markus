FactoryBot.define do
  factory :role do
    association :user, factory: :end_user
    course { Course.order(:id).first || association(:course) }
  end
end
