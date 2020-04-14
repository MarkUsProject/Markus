FactoryBot.define do
  factory :assignment_stat do
    association :assignment
    grade_distribution_percentage { '1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0' }
  end
end
