FactoryBot.define do
  factory :test_batch do
    course { Course.order(:id).first || association(:course) }
  end
end
